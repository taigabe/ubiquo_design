class PageTemplate < ActiveRecord::Base
  has_attached_file :thumbnail
  has_many :page_template_block_types
  has_many :block_types, :through => :page_template_block_types 
  has_many :page_template_component_types
  has_many :component_types, :through => :page_template_component_types  
  has_many :pages

  validates_presence_of :name, :key
  validates_attachment_presence :thumbnail
  validates_uniqueness_of :key

  
end
