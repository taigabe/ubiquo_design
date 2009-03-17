class PageTemplateBlockType < ActiveRecord::Base
  validates_presence_of :block_type, :page_template
  validates_uniqueness_of :block_type_id, :scope => :page_template_id
  
  belongs_to :block_type
  belongs_to :page_template
end
