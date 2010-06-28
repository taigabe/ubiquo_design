class Page < ActiveRecord::Base
  belongs_to :page_template
  belongs_to :published, :class_name => 'Page', :foreign_key => 'published_id', :dependent => :destroy
  has_one :draft, :class_name => 'Page', :foreign_key => 'published_id'
  has_many :blocks, :dependent => :destroy do
    def as_hash
      self.collect{|block|[block.block_type.key, block]}.to_hash
    end
  end

  after_create :assign_default_blocks
  after_save :update_modified
  after_destroy :pending_publish_on_destroy_published

  validates_presence_of :name
  validates_presence_of :url_name
  validates_format_of :url_name, :with => /\A[a-z0-9\/\_\-]*\Z/
  validates_uniqueness_of :url_name, 
                          :scope => [:published_id],
                          :if => Proc.new { |page| page.pending_publish? },
                          :allow_blank => true
  validates_presence_of :page_template

  named_scope :published, 
              :conditions => ["pages.published_id IS NULL AND pages.pending_publish = ?", false]
  named_scope :drafts, 
              :conditions => ["pages.published_id IS NOT NULL OR pages.pending_publish = ?", true]
  
  # Generic find for pages (by ID, url_name or record)
  def self.find_by(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_url_name(something.to_s, options)
    when Page
      something
    else
      nil
    end
  end

  # Returns the most appropiate published page for that url, raises an
  # Exception if no match is found
  def self.with_url url
    url_name = url.is_a?(Array) ? url.join('/') : url
    page = find_by_url_name(url_name)

    # Try to consider the last portion as the slug
    url_name = returning(url_name.split('/')) do |portions|
      portions.size > 1 ? portions.pop : portions
    end.join('/') unless page

    returning page || find_by_url_name(url_name) do |page|
      raise ActiveRecord::RecordNotFound.new("Page with url '#{url_name}' not found") unless page
    end
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

  # Returns wheter the page contains components that have required component params
  def has_required_params?
    components = self.blocks.map(&:components).flatten
    widgets = components.map(&:widget).flatten.uniq
    requires = widgets.map do |widget|
      widget.component_params.map(&:is_required)
    end.flatten
    requires.include?(true)
  end

  def assign_default_blocks
    desired_blocks = page_template.block_types.each do |bt|
      Block.create_for_block_type_and_page(bt, self) if bt.default_block.nil?
    end
    true
  end

  def clear_published_page   
    published.destroy unless pending_publish?
  end

  def default_blocks
    page_template.block_types.map(&:default_block).compact
  end

  def default_block_as_hash
    default_blocks.collect do |block|
      [block.block_type.key, block]
    end.to_hash
  end

  def all_blocks
    all_blocks_as_hash.values
  end

  def all_blocks_as_hash
    blocks.as_hash.reverse_merge(default_block_as_hash)
  end

  def is_using_default?(block_type)
    block_type = BlockType.find_by(block_type)
    all_blocks_as_hash[block_type.key] == default_block_as_hash[block_type.key]
  end

  def publish
    begin
      transaction do
        self.clear_published_page
        published_page = self.clone
        published_page.pending_publish = false
        published_page.save!
        published_page.blocks.destroy_all
        self.blocks.each do |block|
          new_block = block.clone
          new_block.page = published_page
          new_block.save!
          uhook_publish_block_components(block, new_block) do |component, new_component|
            uhook_publish_component_asset_relations(component, new_component)
          end
        end
        self.update_attributes(:is_modified => false,
                               :pending_publish => false,
                               :published_id => published_page.id)
        published_page.reload
      end
      return true
    rescue Exception => e
      return false
    end
  end

  # if you remove published page copy, draft page will be pending publish again
  def pending_publish_on_destroy_published
    if self.is_published? && self.draft
      self.draft.update_attributes(:pending_publish => true)
    end
  end
  
  def wrong_components_ids
    self.blocks.map(&:components).flatten.reject(&:valid?).map(&:id)
  end

  def is_draft?
    published_id? || (!published_id? && pending_publish?)
  end

  def is_published?
    !is_draft?
  end

  def is_linkable?
    is_published? && !has_required_params?
  end

  def update_modified(value=true)
    if self.changes["is_modified"].nil? && self.is_modified?!=value
      self.is_modified = value
      self.save
    end
  end

end
