# encoding: UTF-8
class Page < ActiveRecord::Base

  serialize :expiration, Hash

  belongs_to :published, :class_name => 'Page', :foreign_key => 'published_id', :dependent => :destroy
  belongs_to :parent, :class_name => 'Page', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Page', :foreign_key => 'parent_id'
  has_one :draft, :class_name => 'Page', :foreign_key => 'published_id', :dependent => :nullify
  has_many :blocks, :dependent => :destroy do
    def as_hash
      self.collect{|block|[block.block_type, block]}.to_hash
    end
  end
  has_many :widgets, :through => :blocks

  before_save :compose_url_name_with_parent_url
  before_create :assign_template_blocks
  before_save :update_modified, :if => :is_the_draft?
  after_destroy :is_modified_on_destroy_published

  validates_presence_of :name
  validates_presence_of :url_name, :if => lambda{|page| page.url_name.nil?}
  validates_format_of :url_name, :with => /\A[a-zñ0-9\/\_\-]*\Z/
  validates_presence_of :page_template

  # No other page with the same url_name
  validate :uniqueness_url_name
  def uniqueness_url_name
    if self.is_the_draft?
      exclude_ids = [self.id]
      if self.published_id.present?
        exclude_ids << self.published_id
      end
      exclude_ids = exclude_ids.compact
      conditions = ["id NOT IN (?)", exclude_ids] unless exclude_ids.empty?
      current_page = Page.find_by_url_name(self.url_name, :conditions => conditions)
      if current_page.present?
        self.errors.add(:url_name, :taken)
      end
    end
  end

  include ActionController::UrlWriter

  # Returns the sql conditions that determine that a page is the published instance
  def self.published_conditions
    ["pages.published_id IS NULL AND pages.is_modified = ?", false]
  end

  named_scope :published,
              :conditions => Page.published_conditions
  named_scope :drafts,
              :conditions => ["pages.published_id IS NOT NULL OR pages.is_modified = ?", true]
  named_scope :statics,
              :conditions => ["pages.is_static = ?", true]

  DEFAULT_TEMPLATE_OPTIONS = {
    :layout => 'main',
    :cols => 4,
  }

  # Returns the most appropiate published page for that url, raises an
  # Exception if no match is found.
  def self.with_url url
    url_name = url.is_a?(Array) ? url.join('/') : url
    page = find_by_url_name(url_name)

    # Try to consider the last portion as the slug
    url_name = url_name.split('/').tap do |portions|
      portions.size > 1 ? portions.pop : portions
    end.join('/') unless page

    (page || find_by_url_name(url_name)).tap do |page|
      raise ActiveRecord::RecordNotFound.new("Page with url '#{url_name}' not found") unless page
    end
  end

  # Initialize pages as drafts.
  def initialize(attrs = {})
    attrs ||= {}
    super attrs.reverse_merge!(:is_modified => true)
  end

  # filters:
  #   :text: String to search in page name
  #
  # options: find_options
  def self.filtered_search(filters = {}, options = {})
    scopes = create_scopes(filters) do |filter, value|
      case filter
        when :text
          { :conditions => ["upper(pages.name) LIKE upper(?)", "%#{value}%"] }
      end
    end

    apply_find_scopes(scopes) do
      find(:all, options)
    end
  end

  def clear_published_page
    published.destroy if published?
  end

  def clear_published_page!
    ret = clear_published_page
    raise ActiveRecord::ActiveRecordError, ret.errors.full_messages.join("\n") if published? && !ret
    ret
  end

  def all_blocks_as_hash
    blocks.as_hash
  end


  # Returns the full url where this page is available
  def url(options = {})
    File.join(url_prefix(options), url_name)
  end

  # Returns the full url
  # Possible options:
  #   :scope => scope where this page is being generated. It's not related to Scope!
  def absolute_url(options = {})
    custom_url(options) || "http://#{File.join(host || "", url)}"
  end

  # Returns the appropiate host for this page.
  # To overwrite the page's locale use the +locale+`parameter
  def host(options = {})
    Ubiquo::Settings[:ubiquo_design][:public_host].call(options)
  end

  # Returns any possible applicable prefix for the url, to be placed before url_name
  def url_prefix(options = {})
    ''
  end

  # Returns a string only if a page has its own rules to build its url
  def custom_url(options = {})
    url_for(options_for_url(options))
  end

  # Returns a hash with options to use in a url_for method to generate the url of self
  def options_for_url(url_for_options = {})
    # there are custom routes for actions other than :show
    unless url_for_options[:action] && url_for_options[:action].to_s != 'show'
      # url must be an array of components to avoid a rails escaping bug
      url = "#{self.url(url_for_options)}/#{url_for_options.delete(:url)}".split('/').delete_if(&:blank?)
    end
    {
      :controller => '/pages',
      :action => 'show',
      :url => url,
      :key => nil, # to overwrite current key in params
      :host => host
    }.merge(url_for_options)
  end

  def publish
    begin
      transaction do
        self.clear_published_page!
        published_page = self.clone
        published_page.attributes = {
          :is_modified => false,
          :published_id => nil
        }

        published_page.save!

        raise ActiveRecord::ActiveRecordError, "Cannot delete assigned blocks" unless published_page.blocks.destroy_all.all?

        self.blocks.each do |block|
          new_block = block.clone
          new_block.page = published_page
          new_block.save!
          uhook_publish_block_widgets(block, new_block) do |widget, new_widget|
            uhook_publish_widget_relations(widget, new_widget)
          end
        end

        published_page.reload.update_attributes!(:is_modified => false)

        self.update_attributes!(
          :is_modified => false,
          :published_id => published_page.id
        )

        expire
      end
      return true
    rescue StandardError => e
      return false
    end
  end

  # Destroy the published page copy if exists.
  def unpublish
    if self.published
      self.published.destroy
    elsif self.draft
      self.destroy
    end
  end

  def self.expire_all
    # TODO generalize
    Rails.logger.debug "Expiring all Varnish cache"
    UbiquoDesign.cache_manager.send(:ban, ['',"."])
  end

  def self.expire elements = []
    ids = elements.map {|id| id.is_a?(Page) ? id.id : id}
    pages = Page.find(:all, :conditions => {:id => ids})
    pages.map { |page| (page.expire; page) rescue nil }.compact
  end

  def self.expire_url(url)
    UbiquoDesign.cache_manager.expire_url(url)
  end

  def expire
    ActionController::Base.perform_caching ?
      UbiquoDesign.cache_manager.expire_page(self) : true
  end

  # Returns true if the UbiquoUser +user+ can expire this page
  def can_be_expired_by?(user)
    user.is_superadmin? ||
      Ubiquo::Settings[:ubiquo_design][:page_can_be_expired?].call(self, user)
  end

  def can_be_removed_by?(user)
    key.blank? && user.has_permission?('remove_pages')
  end

  # Returns true if the page has been published.
  def published?
    published_id
  end

  # if you remove published page copy, draft page will be pending publish again.
  def is_modified_on_destroy_published
    if self.is_the_published? && self.draft
      self.draft.update_attributes(:is_modified => true)
    end
  end

  # returns a ids collection of ids of widgets with errors on page.
  def wrong_widgets_ids
    self.blocks.map(&:widgets).flatten.reject(&:valid?).map(&:id)
  end

  # Returns true if the page is the draft version.
  def is_the_draft?
    published_id? || (!published_id? && is_modified?)
  end

  # Returns true if this page is the published one.
  def is_the_published?
    !is_the_draft?
  end

  # Returns true if the page can be accessed directly,
  # i.e. does not have required params.
  def is_linkable?
    #TODO implement this method
    is_the_published?
  end

  # Returns true if the page can be previewed.
  def is_previewable?
    Ubiquo::Config.context(:ubiquo_design).get(:allow_page_preview) &&
      self.blocks.map(&:widgets).flatten.reject(&:is_previewable?).blank?
  end

  # Returns a hash with page template options. Returns default values
  # merged with specified options in UbiquoDesign::Structure.
  def template_options
    DEFAULT_TEMPLATE_OPTIONS.merge(
      UbiquoDesign::Structure.get(:page_template => page_template)[:options] || {}
    )
  end

  # Returns the layout to use for this page. If layout is not
  # specified in UbiquoDesign::Structure, returns a default value.
  def layout
    template_options[:layout]
  end

  # Returns the number of columns for page template. If there aren't
  # specified in UbiquoDesign::Structure, returns a default value.
  def template_cols
    template_options[:cols]
  end

  # Returns a collection of templates defined in UbiquoDesign::Structure.
  def self.templates
    UbiquoDesign::Structure.find(:page_templates)
  end

  def template_structure
    blocks = UbiquoDesign::Structure.get(:page_template => self.page_template)[:blocks]
    blocks.map do |block|
      cols = block.values.flatten.first[:options][:cols] rescue Block::DEFAULT_BLOCK_OPTIONS[:cols]
      subblocks = (block.values.flatten.last.try(:[], :subblocks) || []).map do |sb|
        [sb.keys.first, sb.values.flatten.first[:options][:cols]]
      end
      [block.keys.first, cols, subblocks]
    end
  end

  # Given a page template, returns the blocks that it has, as a list of identifiers
  def self.blocks(template)
    UbiquoDesign::Structure.find(:blocks, :page_template => template)
  end

  # Returns the widgets available for at least one block of this page
  def available_widgets
    available_widgets_per_block.values.flatten.uniq.sort_by{ |widget| Widget.default_name_for widget }
  end

  # Returns a hash containing, for each block, the widgets that can be assigned
  def available_widgets_per_block
    {}.tap do |widgets_per_block|
      blocks.each do |block|
        widgets_per_block[block.block_type] = UbiquoDesign::Structure.find(
          :widgets,
          {:page_template => page_template, :block => block.block_type}
        ).sort_by{ |widget| Widget.default_name_for widget }
      end
    end
  end

  # Changes to true the value of is_modified field.
  # Is used to differentiate draft pages with changes.
  def update_modified(save = false)
    write_attribute(:is_modified, true) unless is_modified_change
    self.save if save
  end

  # Adds the widget to page, on the block with the given key. If the
  # block doesn't exist, create it and relates with the page.
  # Returns false if there are some problem saving page, creating
  # block or relating widget.
  def add_widget(block_key, widget)
    begin
      transaction do
        self.save! if self.new_record?
        block = self.blocks.select { |b| b.block_type == block_key.to_s }.first
        block ||= Block.create!(:page_id => self.id, :block_type => block_key.to_s)
        block.widgets << widget
        uhook_add_widget(widget) do
          widget.save!
        end
      end
    rescue StandardError => e
      return false
    end
  end

  %w{client server}.each do |expiration_type|
    define_method "#{expiration_type}_expiration" do
      setting = Ubiquo::Settings[:ubiquo_design][:page_ttl]
      default_time = setting[expiration_type.to_sym][:default] if setting[expiration_type.to_sym]
      (expiration && expiration[expiration_type]) || default_time
    end

    define_method "#{expiration_type}_expiration=" do |val|
      self.expiration ||= {}
      setting = Ubiquo::Settings[:ubiquo_design][:page_ttl]
      minimum_time = setting[expiration_type.to_sym][:minimum] if setting[expiration_type.to_sym]
      self.expiration[expiration_type] = [val.to_i, minimum_time].max
    end
  end

  private

  def compose_url_name_with_parent_url
    if self.parent
      self.url_name = parent.url_name + "/" + url_name.gsub(/^#{parent.url_name}\//, '')
    end
  end

  def assign_template_blocks
    block_keys = []
    block_types = UbiquoDesign::Structure.get(:page_template => self.page_template)[:blocks] || []
    block_types.each do |block_type|
      subblocks = (block_type.values.flatten.last[:subblocks] rescue [])
      if subblocks.present?
        block_keys += subblocks.map(&:keys).flatten
      else
        block_keys << block_type.keys.first
      end
    end
    block_keys.each do |key|
      self.blocks << Block.create(:block_type => key.to_s)
    end
  end

end
