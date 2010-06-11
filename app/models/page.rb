class Page < ActiveRecord::Base
  belongs_to :page_template
  has_many :blocks, :dependent => :destroy do
    def as_hash
      self.collect{|block|[block.block_type.key, block]}.to_hash
    end
  end

  after_create :assign_default_blocks
  before_validation_on_create :assign_default_is_public
  after_destroy :clear_published_page
  after_save :update_modified

  validates_presence_of :name
  validates_presence_of :url_name, :if => lambda{ |page|
    page.url_name.nil?
  }
  validates_format_of :url_name, :with => /\A[a-z0-9\/\_\-]*\Z/
  validates_uniqueness_of :url_name, :scope => [:is_public], :allow_blank => true
  validates_presence_of :page_template

  named_scope :public, :conditions => { :is_public => true }
  named_scope :private, :conditions => { :is_public => false }
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
    component_types = components.map(&:component_type).flatten.uniq
    requires = component_types.map do |component_type|
      component_type.component_params.map(&:is_required)
    end.flatten
    requires.include?(true)
  end

  def assign_default_blocks
    desired_blocks = page_template.block_types.each do |bt|
      Block.create_for_block_type_and_page(bt, self) if bt.default_block.nil?
    end
    true
  end

  def assign_default_is_public
    self.is_public = false if(self.is_public.nil?)
    true
  end

  def clear_published_page
    published.destroy if self.is_published?
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
        self.published.destroy unless self.published.nil?
        public_page = self.clone
        public_page.is_public = true
        public_page.save!
        public_page.blocks.destroy_all
        self.blocks.each do |block|
          new_block = block.clone
          new_block.page = public_page
          new_block.save!
          uhook_publish_block_components(block, new_block) do |component, new_component|
            uhook_publish_component_asset_relations(component, new_component)
          end
        end
        self.update_modified(false)
        public_page.reload
      end
      return true
    rescue
      return false
    end
  end
  
  def wrong_components_ids
    self.blocks.map(&:components).flatten.reject(&:valid?).map(&:id)
  end

  def published
    Page.public.find_by_url_name(self.url_name)
  end

  def is_published?
    published.present?
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
