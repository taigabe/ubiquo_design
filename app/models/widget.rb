# -*- coding: utf-8 -*-
class Widget < ActiveRecord::Base

  INACCEPTABLE_OPTIONS = %w{options widget widget_id block block_id position}

  @@behaviours = {}

  cattr_accessor :behaviours

  validates_presence_of :name, :block

  belongs_to :block

  attr_protected :options, :options_object

  before_save :update_position
  after_save :update_page
  after_destroy :update_page

  def self.behaviour(name, options={}, &block)
    @@behaviours[name] = {:options => options, :proc => block}
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

  def update_position
    self.position = (block.widgets.map(&:position).max || 0)+1 if self.position.nil?
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

  # Returns the default name for the given +widget+ type
  def self.default_name_for widget
    I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.name")
  end

  # Returns the default description for the given +widget+ type
  def self.default_description_for widget
    I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.description")
  end

  # Returns true if the widget has editable options
  def is_configurable?
    self.class.is_configurable?
  end

  # Returns true if the widget type has editable options
  def self.is_configurable?
    allowed_options.present?
  end

  # Returns the key representing the widget type
  def key
    self.class.to_s.underscore.to_sym
  end

  # Returns a Widget class given a key (inverse of Widget#key)
  def self.class_by_key key
    key.to_s.classify.constantize
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
    self.block.reload.page.reload.update_modified(true)
  end
end
