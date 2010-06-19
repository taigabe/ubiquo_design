require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::PagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_get_index
    login_as
    get :index
    assert_response :success
    assert_not_nil pages=assigns(:pages)
    assert pages.size > 0
    pages.each do |page|
      assert_equal page.is_published?, false
    end
  end

  def test_shouldnt_get_index_without_permission
    login_as :eduard
    get :index
    assert_response :forbidden
  end

  def test_should_get_new
    login_as
    get :new
    assert_response :success
  end

  def test_should_create_page_with_default_blocks
    login_as
    assert_difference('Page.count') do
      post :create, :page => { :name => "Custom page", :url_name => "custom_page", :page_template_id => page_templates(:one).id }
    end

    assert page = assigns(:page)
    assert_equal page.all_blocks.size, page.page_template.block_types.size
    assert_equal page.is_published?, false

    assert_redirected_to ubiquo_pages_path
  end

  def test_should_create_page_with_some_default_blocks
    login_as
    assert_difference('Page.count') do
      post :create, :page => {:name => "Custom page", :url_name => "custom_page", :page_template_id => page_templates(:two).id }
    end

    assert page = assigns(:page)
    assert_equal page.all_blocks.size, page.page_template.block_types.size

    assert_redirected_to ubiquo_pages_path
  end

  def test_should_get_edit
    login_as
    get :edit, :id => pages(:one).id
    assert_response :success
  end

  def test_should_update_page
    login_as
    put :update, :id => pages(:one).id, :page => {:name => "Custom page", :url_name => "custom_page", :page_template_id => page_templates(:one).id }
    assert_redirected_to ubiquo_pages_path
  end

  def test_should_destroy_page
    login_as
    # if you remove a draft page, its published page is removed too 
    assert_difference('Page.count', -2) do
      delete :destroy, :id => pages(:one_design).id
    end

    assert_redirected_to ubiquo_pages_path
  end
end
