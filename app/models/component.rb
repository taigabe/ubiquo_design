class Component < ActiveRecord::Base
  
  INACCEPTABLE_OPTIONS = %w{options component_type component_type_id block block_id position options options_object update_position prepare_yaml define_method_accessors allowed_options_storage name}
  
  belongs_to :component_type
  belongs_to :block

  after_save :update_page
  after_destroy :update_page

  validates_presence_of :component_type, :block, :name
  #validates_uniqueness_of :position, :scope => :block_id

  attr_protected :options, :options_object

  before_save :update_position
  
  def update_position
    self.position = (block.components.map(&:position).max || 0)+1 if self.position.nil? 
  end

  def initialize(a = {})
    define_method_accessors self.class.allowed_options
    super(a)
    self.options_object = [self.class.allowed_options].flatten.inject({}){|acc, v| acc[v]=self.send(v); acc}
  end

  def after_find
    self.options_object = YAML::load(self.options)
  end

  def prepare_yaml
    self.options = options_object.to_yaml
  end

  def define_method_accessors(names)
    [names].flatten.each do |name|
      eval(%{
        def self.#{name}
          options_object[:#{name}]
        end
        def self.#{name}=(value)
          options_object[:#{name}] = value
          prepare_yaml
          value
        end
      })
    end
  end

  def options_object
    @options_object ||= {}
  end

  def options_object=(hash)
    @options_object = hash
    prepare_yaml
    options_object.each do |key, value|
      define_method_accessors key
      send("#{key}=", value)
    end
    hash
  end

  # cattr_accessor :allowed_options_storage
  def self.allowed_options=(opts)
    opts = [opts].flatten
    unallowed_options = opts.map(&:to_s)&INACCEPTABLE_OPTIONS
    raise "Inacceptable options: '%s'" % unallowed_options.join(', ') unless unallowed_options.blank?
    self.cattr_accessor :allowed_options_storage
    self.allowed_options_storage = opts
  end
  def self.allowed_options
    self.allowed_options_storage ||= []
  end
  
  # Fixes clone method. Also copy 'options' attribute
  def clone
    cloned = super
    cloned.options_object = self.options_object
    cloned
  end

  private
  
  # When a block is saved, the associated page must change its modified attribute 
  def update_page
    self.block.reload.page.reload.update_modified
  end
end
