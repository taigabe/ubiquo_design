# -*- coding: utf-8 -*-
module UbiquoDesign::Concerns::Models::Widget
  extend ActiveSupport::Concern

  included do
    INACCEPTABLE_OPTIONS = %w{options widget widget_id block block_id position}

    WIDGET_TTL = {
      :default => Ubiquo::Settings[:ubiquo_design][:widget_ttl]
    }

    

    @inheritable_attributes = inheritable_attributes.merge(
      :previewable => true,
      :clonation_exceptions => [:asset_relations]
    )

    cattr_accessor :behaviours

    attr_accessor :update_page_denied

    validates_presence_of :name, :block

    belongs_to :block

    serialize :options, Hash
    attr_protected :options

    before_create :set_version

    before_save :update_position
    after_save :update_page
    after_destroy :update_page

    named_scope :published,
                :conditions => ::Page.published_conditions,
                :include => {:block => :page}

    mattr_accessor :behaviours
    self.behaviours = {}
  end

  module ClassMethods

    def behaviour(name, options={}, &block)
      self.behaviours[name] = {:options => options, :proc => block}
    end

    def allowed_options=(opts)
      opts = [opts].flatten
      unallowed_options = opts.map(&:to_s)&INACCEPTABLE_OPTIONS
      raise "Inacceptable options: '%s'" % unallowed_options.join(', ') unless unallowed_options.blank?
      self.cattr_accessor :allowed_options_storage
      self.allowed_options_storage = opts
      opts.each do |option|
        define_method(option) do
          self.options[option]
        end
        define_method("#{option}=") do |value|
          self.options[option] = value
        end
        define_method("#{option}_before_type_cast") do
          self.options[option]
        end
      end
    end

    def allowed_options
      self.allowed_options_storage ||= []
    end

    # Returns the default name for the given +widget+ type
    def default_name_for widget
      I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.name")
    end

    # Returns the default description for the given +widget+ type
    def default_description_for widget
      I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.description")
    end

    # Returns true if the widget type has editable options
    def is_configurable?
      allowed_options.present?
    end

    # Returns a Widget class given a key (inverse of Widget#key)
    def class_by_key key
      key.to_s.classify.constantize
    end

    # Returns a hash containing the defined widget_groups in design structure, and
    # for each group, the identifiers of the widgets that compose it
    def groups
      {}.tap do |groups|
        UbiquoDesign::Structure.widget_groups.each do |widget_group|
          groups[widget_group.keys.first] = widget_group.values.first.select do |h|
            h.keys.include?(:widgets)
          end.first[:widgets].map(&:keys).flatten
        end
      end
    end

    def is_previewable?
      read_inheritable_attribute :previewable
    end

    def previewable(value)
      write_inheritable_attribute :previewable, (value == true)
    end

    def clonation_exception(value)
      exceptions = clonation_exceptions + [value.to_sym]
      write_inheritable_attribute :clonation_exceptions, exceptions.uniq
    end

    def clonation_exceptions
      Array(read_inheritable_attribute(:clonation_exceptions))
    end

    def is_a_clonable_has_one?(reflection)
      reflection = self.reflections[reflection.to_sym] unless reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
      reflection.macro == :has_one && is_relation_clonable?(reflection.name)
    end

    def is_a_clonable_has_many?(reflection)
      reflection = self.reflections[reflection.to_sym] unless reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
      reflection.macro == :has_many &&
        !reflection.options.include?(:through) &&
        is_relation_clonable?(reflection.name)
    end

    def is_relation_clonable?(relation_name)
      !clonation_exceptions.include?(relation_name.to_sym)
    end
  end

  def without_page_expiration
    self.update_page_denied = true
    yield
    self.update_page_denied = false
  end

  def update_position
    self.position = (block.widgets.map(&:position).max || 0)+1 if self.position.nil?
  end

  # +options+ should be an empty hash by default (waiting for rails #1736)
  def options
    read_attribute(:options) || write_attribute(:options, {})
  end

  # Returns true if the widget has editable options
  def is_configurable?
    self.class.is_configurable?
  end

  # Returns the key representing the widget type
  def key
    self.class.to_s.underscore.to_sym
  end

  # Returns the page this widget is in
  def page
    # Not using delegate due to 'block' clash name...
    block.page
  end

  def is_previewable?
    self.class.is_previewable?
  end

  # Returns true if the widget can be retrieved in a unique url independently of
  # the page it is placed in or any other params
  def has_unique_url?
    url.present?
  end

  # If the widget +has_unique_url?+, returns a string with the url where this widget
  # can be retrieved. Else returns a +blank?+ value
  def url
    false
  end

  # Expires this widget, using the configured cache_manager
  def expire(options = {})
    UbiquoDesign.cache_manager.expire(self, options)
  end

  private

  # When a block is saved, the associated page must change its modified attribute
  def update_page
    ignore_scope(true) do
      if self.update_page_denied.blank?
        if block = self.block
          block.reload
          if widget_page = block.page
            widget_page.reload
            widget_page.update_modified(true) unless widget_page.is_modified?
          end
        end
      end
    end
  end

  # Sets initial version number
  def set_version
    self.version = 0
  end
end
