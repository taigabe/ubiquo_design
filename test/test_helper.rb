require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

class ActiveSupport::TestCase
end


class TestComponent < Component
  self.allowed_options = :title, :description
end
