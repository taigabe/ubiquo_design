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

  def test_should_get_page_by_key
    assert_nothing_raised do
      get :show, :key => pages(:one).key
    end
  end

  def test_should_use_metatags
    get :show, :key => pages(:one).key
    assert_select "title", pages(:one).meta_title
  end

  def test_should_print_default_desc_and_keywords
    pages(:one).update_attribute :meta_description, 'description'
    pages(:one).update_attribute :meta_keywords, %{key_on'e,key_tw"o}
    get :show, :key => pages(:one).key
    assert_select "meta[name=description][content=description]"
    assert_select "meta[name=keywords][content=key_on'e,key_tw&quot;o]"
  end

  def test_should_not_get_page_by_inexistent_key
    assert_raise ActiveRecord::RecordNotFound do
      get :show, :key => 'non_existent'
    end
  end

  def test_should_check_if_is_a_widget_request
    @controller.expects(:widget_request?).at_least_once
    get :show, :key => pages(:one).key, :widget => 1
  end

  def test_should_determine_if_is_a_widget_request_using_widget_param
    @controller.expects(:params).returns({:widget => 1})
    assert @controller.send(:widget_request?)

    @controller.expects(:params).returns({:widget => nil})
    assert !@controller.send(:widget_request?)
  end

  test "should respond with cache headers when the page has client_expiration greater than 0" do
    page = create_page(:url_name => 'no-cache', :client_expiration => 15)
    page.publish

    get :show, :url => ["no-cache"], :locale => 'ca'
    assert_response :success
    assert_equal page.published, assigns(:page)
    assert_equal "max-age=15, public", @response.headers['Cache-Control']
  end

  test "should respond with no cache headers when the page has client_expiration time equals to 0" do
    page = create_page(:url_name => 'no-cache', :client_expiration => 0)
    page.publish
    now = Time.now
    Time.stubs(:now).returns(now)

    get :show, :url => ["no-cache"], :locale => 'ca'
    assert_response :success
    assert_equal page.published, assigns(:page)
    assert_equal "no-cache, no-store, max-age=0, must-revalidate, public",
                 @response.headers['Cache-Control']
    assert_equal "no-cache", @response.headers["Pragma"]
    assert_equal now.to_i.to_s, @response.headers["Etag"]
    assert_equal "Fri, 01 Jan 1990 00:00:00 GMT", @response.headers["Expires"]
  end

  test "should detect enabled varnish cache manager subclasses to attach its expiration headers" do
    UbiquoDesign.expects(:cache_manager).returns(UbiquoDesign::CacheManagers::Varnish)
    assert @controller.send(:varnish_enabled?)

    UbiquoDesign.expects(:cache_manager).returns(Class.new(UbiquoDesign::CacheManagers::Varnish))
    assert @controller.send(:varnish_enabled?)

    UbiquoDesign.expects(:cache_manager).returns(UbiquoDesign::CacheManagers::Memcache)
    assert !@controller.send(:varnish_enabled?)
  end


end
