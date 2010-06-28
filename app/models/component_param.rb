class ComponentParam < ActiveRecord::Base
  validates_presence_of :name, :widget_id  
  validates_inclusion_of :is_required, :in => [true, false]
  validates_uniqueness_of :name, :scope => :widget_id
  belongs_to :widget
end
