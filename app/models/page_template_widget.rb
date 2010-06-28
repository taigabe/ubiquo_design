class PageTemplateWidget < ActiveRecord::Base
  validates_presence_of :widget, :page_template
  validates_uniqueness_of :widget_id, :scope => :page_template_id
  
  belongs_to :widget
  belongs_to :page_template
end
