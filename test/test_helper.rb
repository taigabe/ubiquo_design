require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

class ActiveSupport::TestCase

  RoutingFilter.active = false if defined?(RoutingFilter)

  # creates a (draft) page
  def create_page(options = {})
    Page.create({:name => "Custom page",
      :url_name => "custom_page",
      :page_template => "static",
      :published_id => nil,
      :is_modified => true
    }.merge(options))
  end
end

class TestWidget < Widget
  self.allowed_options = :title, :description
end

class TestWidgetWithValidations < Widget
  self.allowed_options = :number
  self.validates_numericality_of :number
end

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end
