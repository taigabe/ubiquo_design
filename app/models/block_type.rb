class BlockType < ActiveRecord::Base
  validates_presence_of :name, :key
  validates_uniqueness_of :key
  validate :valid_default
  
  has_many :blocks
  
  has_many :page_template_block_types
  has_many :page_templates, :through => :page_template_block_types

  # Return the default_block for this block type  
  def default_block
    frontpage_category = PageCategory.find_by_url_name('')
    return unless frontpage_category
    page = Page.public_scope do
      Page.find_by_url_name_and_page_category_id('', frontpage_category.id)
    end
    return nil if !self.can_use_default_block? || page.nil?
    page.nil? ? nil : page.blocks.as_hash[self.key]
  end
  
  def valid_default
    errors.add :default_block, t('ubiquo.design.block_error') if !default_block.nil? && default_block.block_type!=self
  end
  
  def self.find_by(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_key(something.to_s, options)
    when BlockType
      something
    else
      nil
    end
  end
end
