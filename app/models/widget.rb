class Widget < ActiveRecord::Base
  validates_presence_of :name, :key, :subclass_type
  validates_uniqueness_of :key
  has_many :component_params
  has_many :components, :order => 'components.position ASC'
end
