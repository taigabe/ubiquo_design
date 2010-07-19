class Widget < ActiveRecord::Base

  INACCEPTABLE_OPTIONS = %w{options widget widget_id block block_id position}

  @@behaviours = {}

  cattr_accessor :behaviours

  validates_presence_of :name, :key, :subclass_type
  validates_uniqueness_of :key

  belongs_to :block

  def self.behaviour(name, options={}, &block)
    @@behaviours[name] = {:options => options, :block => block}
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

end
