require File.dirname(__FILE__) + "/../test_helper.rb"

class PagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_show
    get :show, :url => Page.published.first.url_name
    assert_response :success
    assert_not_nil assigns(:blocks)
  end

  def test_should_return_404_if_no_page
    assert_raise ActiveRecord::RecordNotFound do
      get :show, :url => 'inexistent'
      assert_response :success
    end
  end

  def test_should_return_404_if_page_not_published
    assert_raise ActiveRecord::RecordNotFound do
      get :show, :url => 'unpublished'
      assert_response :success
    end
  end

  def test_should_consider_first_all_route
    assert_nothing_raised do
      get :show, :url => 'long/url'
    end
  end

  def test_should_consider_then_last_portion_as_slug
    assert_nothing_raised do
      get :show, :url => 'long/url/slug'
    end
  end

  def test_should_recognize_root
    assert_recognizes(
      { :controller => "pages", :action => "show", :url => [] },
      ""
    )
  end
  
  def test_should_recognize_single_page
    assert_recognizes(
      { :controller => "pages", :action => "show", :url => ['url'] },
      "url"
    )
  end

  def test_should_recognize_page_with_path
    assert_recognizes(
      { :controller => "pages", :action => "show", :url => ['long', 'url'] },
      "long/url"
    )
  end

  def test_should_recognize_single_page_with_page_number
    assert_recognizes(
      { :controller => "pages", :action => "show", :url => ['url'], :page => "12" },
      "url/page/12"
    )
  end

  def test_should_recognize_page_with_page_number
    assert_recognizes(
      { :controller => "pages", :action => "show", :url => ['long', 'url'], :page => "12" },
      "long/url/page/12"
    )
  end

end
