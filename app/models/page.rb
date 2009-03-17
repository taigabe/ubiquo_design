class Page < ActiveRecord::Base

  belongs_to :page_template
  has_many :blocks, :dependent => :destroy do
    def as_hash
      self.collect{|block|[block.block_type.key, block]}.to_hash
    end
  end

  belongs_to :page_type
  belongs_to :page_category

  after_create :assign_default_blocks
  before_validation_on_create :assign_default_is_public
  after_destroy :clear_published_page
  after_save :update_modified

  validates_presence_of :name
  validates_presence_of :url_name, :if => lambda{ |page|
    page.url_name.nil?
  }
  validates_format_of :url_name, :with => /\A[a-z\/\_\-]*\Z/
  validates_uniqueness_of :url_name, :scope => [:page_type_id, :is_public], :allow_blank => true
  validates_presence_of :page_template
  #  validates_presence_of :page_type
  validates_presence_of :page_category

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
    filter_text = unless filters[:text].blank?
      args = ["%#{filters[:text]}%"]
      condition = "pages.name LIKE ?"
      {:find => {:conditions => [condition] + args}}
    else
      {}
    end
    with_scope(filter_text) do
      with_scope(:find => options) do
        Page.find(:all)
      end
    end
  end

  # Get public page given a page_type key, page_category url_name and page url_name
  def self.find_public(page_category_url_name, page_name)
    page_category = PageCategory.find_by_url_name(page_category_url_name)
    raise ActiveRecord::RecordNotFound.new("Cannot find page_category '#{page_category_url_name}'") unless page_category
    page = public_scope do
      #page_category.pages.find_all_by_url_name(page_name)
      page_category.pages.find(:first, :conditions => ["url_name = ?", page_name])
    end
    raise ActiveRecord::RecordNotFound.new("Cannot find public page with page_name '#{page_name}' and page_category '#{page_category_url_name}'") unless page
    page
  end

  # Create a surrouding scope for calls within the block to get only public pages
  def self.public_scope(p = true)
    self.with_scope(:find => {:conditions => ["pages.is_public = ?", p]}) do
      yield
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
          block.components.each do |component|
            new_component = component.clone
            new_component.block = new_block
            new_component.save_without_validation!
            if component.respond_to?(:asset_relations)
              component.asset_relations.each do |asset_relation|
                new_asset_relation = asset_relation.clone
                new_asset_relation.related_object = new_component
                new_asset_relation.save!
              end
            end
            new_component.save! # must validate now
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

  def is_published?
    !published.nil?
  end

  def published
    begin
      Page.find_public(self.page_category.url_name, self.url_name)
    rescue
      nil
    end
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
