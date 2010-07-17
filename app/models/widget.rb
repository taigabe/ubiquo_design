class Widget < ActiveRecord::Base

  @@behaviours = {}

  cattr_accessor :behaviours

  validates_presence_of :name, :key, :subclass_type
  validates_uniqueness_of :key
  has_many :components, :order => 'components.position ASC'

  def self.behaviour(name, options={}, &block)
    @@behaviours[name] = {:options => options, :block => block}
  end

end
