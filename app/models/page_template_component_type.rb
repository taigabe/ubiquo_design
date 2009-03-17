class PageTemplateComponentType < ActiveRecord::Base
  validates_presence_of :component_type, :page_template
  validates_uniqueness_of :component_type_id, :scope => :page_template_id
  
  belongs_to :component_type
  belongs_to :page_template
end
