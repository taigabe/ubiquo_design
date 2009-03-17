require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::PageCategoriesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_get_index
    login_as
    get :index
    assert_response :success
    assert_not_nil assigns(:page_categories)
  end

  def test_should_get_index_with_permission
    login_with_permission :design_management
    get :index
    assert_response :success
  end

  def test_should_not_get_index_without_permission
    login_with_permission
    get :index
    assert_response :forbidden
  end

  def test_should_get_new
    login_as
    get :new
    assert_response :success
  end

  def test_should_create_page_category
    login_as
    assert_difference('PageCategory.count') do
      post :create, :page_category => page_category_attributes
    end

    assert_redirected_to ubiquo_page_categories_path
  end

  def test_should_get_edit
    login_as
    get :edit, :id => page_categories(:one).id
    assert_response :success
  end

  def test_should_update_page_category
    login_as
    put :update, :id => page_categories(:one).id, :page_category => page_category_attributes
    assert_redirected_to ubiquo_page_categories_path
  end

  def test_should_destroy_page_category
    login_as
    assert_difference('PageCategory.count', -1) do
      delete :destroy, :id => page_categories(:one).id
    end

    assert_redirected_to ubiquo_page_categories_path
  end   
  
  private
  
  def page_category_attributes(options = {}) 
    default_options = {:name => 'test_name', :url_name => 'test_url_name'}
    default_options.merge(options)
  end
  
  
end
