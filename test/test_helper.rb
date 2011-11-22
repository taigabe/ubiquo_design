require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

class ActiveSupport::TestCase
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
