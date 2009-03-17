require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::MenuItemsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_get_index
    login_as
    get :index
    assert_response :success
    assert_not_nil assigns(:menu_items)
  end

  def test_should_get_index_with_permission
    login_with_permission :sitemap_management
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

  def test_should_create_menu_item
    login_as
    assert_difference('MenuItem.count') do
      post :create, :menu_item => menu_item_attributes
    end

    assert_redirected_to ubiquo_menu_items_path
  end

  def test_should_get_edit
    login_as
    get :edit, :id => menu_items(:one).id
    assert_response :success
  end

  def test_should_update_menu_item
    login_as
    menu_item = menu_item_attributes.merge(:caption => 'new_caption')
    put :update, :id => menu_items(:one).id, :menu_item => menu_item 
    assert_redirected_to ubiquo_menu_items_path
  end

  def test_should_destroy_menu_item
    login_as
    assert_difference('MenuItem.count', -1) do
      delete :destroy, :id => menu_items(:one).id
    end

    assert_redirected_to ubiquo_menu_items_path
  end
  
  def test_should_set_parent_id_on_new
    login_as
    get :new, {:parent_id => menu_items(:one).id}
    assert_response :success
    assert_select("input#menu_item_parent_id", 1, "Cannot find parent_id on new menu_item")
    assert_select("input#menu_item_parent_id[value=\"#{menu_items(:one).id}\"]", 1, 
      "Cannot find expected parent_id on new menu_item")    
  end
  
  def test_should_set_automatic_menus_on_new_and_edit
    login_as
    get :new
    assert assigns(:automatic_menus), "Menu generators not set on new action"
    get :edit, :id => menu_items(:one).id
    assert assigns(:automatic_menus), "Menu generators not set on edit action"  
  end

  def test_should_be_sortable
    login_as
    root1 = create_menu_item(:caption => 'caption1')
    child11 = create_menu_item(:caption => 'caption11', :parent_id => root1.id)
    child12 = create_menu_item(:caption => 'caption12', :parent_id => root1.id)    
    new_order = [child12, child11].map(&:id)
    xhr :post, :update_positions, {:menu_items_list => new_order, :column => 'menu_items_list'}
    assert_response :success    
    assert_equal root1.children.map(&:id), new_order
  end
  
  private

  def create_menu_item(options = {})
    MenuItem.create(menu_item_attributes(options))  
  end
  
  def menu_item_attributes(options = {})
    default_options = { 
      :caption => "Caption", 
      :url => "http://www.gnuine.com", 
      :description => "Gnuine webpage",
      :is_linkable => true,
      :parent_id => 0,
      :position => 0,
      :automatic_menu_id => nil,
    }
    default_options.merge(options)
  end

 
end
