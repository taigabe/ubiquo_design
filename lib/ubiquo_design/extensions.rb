module UbiquoDesign
  module Extensions
    autoload :Helper, "ubiquo_design/extensions/helper"
    autoload :TestHelper, "ubiquo_design/extensions/test_helper"
  end
end

ActionController::Base.helper(UbiquoDesign::Extensions::Helper)
ActiveSupport::TestCase.send(:include, UbiquoDesign::Extensions::TestHelper)
