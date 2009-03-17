class ComponentParam < ActiveRecord::Base
  validates_presence_of :name, :component_type_id  
  validates_inclusion_of :is_required, :in => [true, false]
  validates_uniqueness_of :name
  belongs_to :component_type
end
