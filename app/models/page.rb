class Page < ActiveRecord::Base
  belongs_to :published, :class_name => 'Page', :foreign_key => 'published_id', :dependent => :destroy
  belongs_to :parent, :class_name => 'Page', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Page', :foreign_key => 'parent_id'
  has_one :draft, :class_name => 'Page', :foreign_key => 'published_id', :dependent => :nullify
  has_many :blocks, :dependent => :destroy do
    def as_hash
      self.collect{|block|[block.block_type, block]}.to_hash
    end
  end

  before_save :compose_url_name_with_parent_url
  before_create :assign_template_blocks
  before_save :update_modified, :if => :is_the_draft?
  after_destroy :is_modified_on_destroy_published

  validates_presence_of :name
  validates_presence_of :url_name, :if => lambda{|page| page.url_name.nil?}
  validates_format_of :url_name, :with => /\A[a-z0-9\/\_\-]*\Z/
  validates_presence_of :page_template

  # No other page with the same url_name
  validate do |page|
    if page.is_the_draft?
      exclude_ids = [page.id]
      if page.published_id.present?
        exclude_ids << page.published_id
      end
      exclude_ids = exclude_ids.compact
      conditions = ["id NOT IN (?)", exclude_ids] unless exclude_ids.empty?
      current_page = Page.find_by_url_name(page.url_name, :conditions => conditions)
      if current_page.present?
        page.errors.add(:url_name, :taken)
      end
    end
  end

  named_scope :published,
              :conditions => ["pages.published_id IS NULL AND pages.is_modified = ?", false]
  named_scope :drafts,
              :conditions => ["pages.published_id IS NOT NULL OR pages.is_modified = ?", true]
  named_scope :statics,
              :conditions => ["pages.is_static = ?", true]


  DEFAULT_LAYOUT = 'main'

  # Returns the most appropiate published page for that url, raises an
  # Exception if no match is found
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

  # Initialize pages as drafts
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

  def all_blocks_as_hash
    blocks.as_hash
  end

  def publish
    begin
      transaction do

        self.clear_published_page
        published_page = self.clone
        published_page.attributes = {
          :is_modified => false,
          :published_id => nil
        }
        
        published_page.save!

        published_page.blocks.destroy_all
        self.blocks.each do |block|
          new_block = block.clone
          new_block.page = published_page
          new_block.save!
          uhook_publish_block_widgets(block, new_block) do |widget, new_widget|
            uhook_publish_widget_asset_relations(widget, new_widget)
          end
        end

        published_page.reload.update_attribute(:is_modified, false)
        
        self.update_attributes(
          :is_modified => false,
          :published_id => published_page.id
        )
      end
      return true
    rescue Exception => e
      return false
    end
  end

  # Returns true if the page has been published
  def published?
    published_id
  end

  # if you remove published page copy, draft page will be pending publish again
  def is_modified_on_destroy_published
    if self.is_the_published? && self.draft
      self.draft.update_attributes(:is_modified => true)
    end
  end

  def wrong_widgets_ids
    self.blocks.map(&:widgets).flatten.reject(&:valid?).map(&:id)
  end

  # Returns true if the page is the draft version
  def is_the_draft?
    published_id? || (!published_id? && is_modified?)
  end

  # Returns true if this page is the published one
  def is_the_published?
    !is_the_draft?
  end

  # Returns true if the page can be accessed directly,
  # i.e. does not have required params
  def is_linkable?
    #TODO implement this method
    is_the_published?
  end

  # Returns true if the page can be previewed
  def is_previewable?
    #TODO Implement this method
    false
  end

  # Returns the layout to use for this page
  def layout
    UbiquoDesign::Structure.get(:page_template => page_template.to_sym)[:options][:layout] rescue DEFAULT_LAYOUT
  end

  def self.templates
    UbiquoDesign::Structure.get[:page_templates].map(&:keys).flatten rescue []
  end

  def self.blocks(template = nil)
    if template
      UbiquoDesign::Structure.get(:page_template => template.to_sym)[:blocks].map(&:keys).flatten rescue []
    else
      #TODO Implement this method with UbiquoDesign::structure
      raise NotImplementedError
    end
  end

  def available_widgets
    UbiquoDesign::Structure.get(:page_template => page_template)[:widgets].map(&:keys).flatten
  end

  def update_modified(save = false)
    write_attribute(:is_modified, true) unless is_modified_change
    self.save if save
  end

  def add_widget(block_key, widget)
    begin
      transaction do
        self.save! if self.new_record?
        block = self.blocks.select { |b| b.block_type == block_key.to_s }.first
        block ||= Block.create!(:page_id => self.id, :block_type => block_key.to_s)
        block.widgets << widget
        widget.save!
      end
    rescue Exception => e
      return false
    end
  end

  private

  def compose_url_name_with_parent_url
    if self.parent
      self.url_name = parent.url_name + "/" + url_name.gsub(/^#{parent.url_name}\//, '')
    end
  end

  def assign_template_blocks
    block_types = Page.blocks(self.page_template)
    block_types.each do |block_type|
      self.blocks << Block.create(:block_type => block_type.to_s)
    end
  end
  
end
