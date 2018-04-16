# -*- coding: utf-8 -*-
class Widget < ActiveRecord::Base

  INACCEPTABLE_OPTIONS = %w{options widget widget_id block block_id position}

  WIDGET_TTL = {
    :default => Ubiquo::Settings[:ubiquo_design][:widget_ttl]
  }

  @@behaviours = {}

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

  named_scope :time_filtered, :conditions => ['start_time IS NOT NULL AND end_time IS NOT NULL']
  named_scope :date_filtered, :conditions => ['start_date IS NOT NULL AND end_date IS NOT NULL']


  # Explanation about now()::time + interval '1 minutes'
  # Example: widget.start_time = 11:00
  # if we execute the operation at 10:55 + 5 the query won't find the widget
  # because overlaps works like start_time <= time < end_time
  # Therefore, we won't find the widget because the end_time is 11:00 is it must be
  # less than the end_time. So, until the current time is 11:00 we won't be able
  # to find the widget. Of course, the warmup job will be created but it could
  # generate some race conditions and maybe the warmup job couldn't be triggered

  # Adding the + 1 to the current time, the code works like this:
  # - Now: 10:54 => (10:54 + 1) + 5 = 11:00 => (10:55 <= 11:00 < 11:00) => No widget
  # - Now: 10:55 => (10:55 + 1) + 5 = 11:01 => (10:56 <= 11:00 < 11:01) => Widget found
  def self.time_filtered_visibility_start_in(interval = 5)
    self.published.
         time_filtered.
         all(:conditions => ["(start_time::time, start_time::time) OVERLAPS (?, interval ?) AND blocks.page_id IS NOT NULL",
                             Time.zone.now + 1.minute,  "#{interval} minutes"],
             :joins => {:block => :page})
  end

  def self.time_filtered_visibility_end_in(interval = 5)
    self.published.
         time_filtered.
         all(:conditions => ["(end_time::time, end_time::time) OVERLAPS (?, interval ?) AND blocks.page_id IS NOT NULL",
                             Time.zone.now + 1.minute, "#{interval} minutes"],
             :joins => {:block => :page})
  end

  def self.date_filtered_visibility_start_at(date = 1.day.from_now)
    self.published.
         date_filtered.
         all(:conditions => ["start_date::date = ? AND blocks.page_id IS NOT NULL", date.to_date],
             :joins => {:block => :page})
  end

  def self.date_filtered_visibility_end_at(date = 1.day.from_now)
    self.published.
         date_filtered.
         all(:conditions => ["end_date::date = ? AND blocks.page_id IS NOT NULL", date.to_date],
             :joins => {:block => :page})
  end

  def without_page_expiration
    self.update_page_denied = true
    yield
    self.update_page_denied = false
  end

  def self.behaviour(name, options={}, &block)
    @@behaviours[name] = {:options => options, :proc => block}
  end

  def update_position
    self.position = (block.widgets.map(&:position).max || 0)+1 if self.position.nil?
  end

  # +options+ should be an empty hash by default (waiting for rails #1736)
  def options
    read_attribute(:options) || write_attribute(:options, {})
  end

  def self.allowed_options=(opts)
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

  # Returns a hash containing the defined widget_groups in design structure, and
  # for each group, the identifiers of the widgets that compose it
  def self.groups
    {}.tap do |groups|
      UbiquoDesign::Structure.widget_groups.each do |widget_group|
        groups[widget_group.keys.first] = widget_group.values.first.select do |h|
          h.keys.include?(:widgets)
        end.first[:widgets].map(&:keys).flatten
      end
    end
  end

  # Returns the page this widget is in
  def page
    # Not using delegate due to 'block' clash name...
    block.page
  end

  def is_previewable?
    self.class.is_previewable?
  end

  def self.is_previewable?
    read_inheritable_attribute :previewable
  end

  def self.previewable(value)
    write_inheritable_attribute :previewable, (value == true)
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

  def self.clonation_exception(value)
    exceptions = clonation_exceptions + [value.to_sym]
    write_inheritable_attribute :clonation_exceptions, exceptions.uniq
  end

  def self.clonation_exceptions
    Array(read_inheritable_attribute(:clonation_exceptions))
  end

  def self.is_a_clonable_has_one?(reflection)
    reflection = self.reflections[reflection.to_sym] unless reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
    reflection.macro == :has_one && is_relation_clonable?(reflection.name)
  end

  def self.is_a_clonable_has_many?(reflection)
    reflection = self.reflections[reflection.to_sym] unless reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
    reflection.macro == :has_many &&
      !reflection.options.include?(:through) &&
      is_relation_clonable?(reflection.name)
  end

  def self.is_relation_clonable?(relation_name)
    !clonation_exceptions.include?(relation_name.to_sym)
  end

  def self.descendants_with_page_expiration
    ['AutomaticMediaComponent']
  end

  private

  # When a block is saved, the associated page must change its modified attribute
  def update_page
    ignore_scope(false) do
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
