require File.dirname(__FILE__) + "/../test_helper.rb"

class PagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_show
    get :show, :url_name => pages(:one).url_name
    assert_response :success
    blocks = assigns(:blocks)
    assert blocks[:block_a], "Cannot find expected block"
  end
  
end
