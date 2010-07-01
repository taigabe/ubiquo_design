require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::ComponentsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_add_component_through_html
    login_as
    assert_difference('Component.count') do
      post :create, :page_id => pages(:one_design).id, :block => pages(:one_design).blocks.first, :widget => widgets(:one)
    end
    assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
    component = assigns(:component)
    assert_not_nil component
    assert_equal component.block, pages(:one_design).blocks.first
    assert_equal component.widget, widgets(:one)
    assert_equal component.widget.name, component.name
  end

  def test_should_add_editable_component_through_js
    login_as
    assert_not_nil editable_component = Widget.find_by_is_configurable(true)
    assert_not_nil not_editable_component = Widget.find_by_is_configurable(false)
    [editable_component, not_editable_component].each do |widget|
      assert_difference('Component.count') do
        xhr :post, :create, :page_id => pages(:one_design).id, :block => pages(:one_design).blocks.first, :widget => widget
      end
      component = assigns(:component)
      assert_not_nil component
      assert component.block == pages(:one_design).blocks.first
      assert component.widget == widget

      assert_select_rjs :insert_html, "block_type_holder_#{component.block.block_type.id}" do
        assert_select "#component_name_field_#{component.id}"
      end
      edition_matches = @response.body.match(/myLightWindow\._processLink\(\$\(\'edit_component_#{component.id}\'\)\)\;/)
      assert_equal edition_matches.nil?, !component.widget.is_configurable?

    end
  end

  def test_shouldnt_add_component_without_permission
    login_with_permission
    assert_no_difference("Component.count") do
      post :create, :page_id => pages(:one_design).id, :block => pages(:one).blocks.first, :widget => widgets(:one)
    end
    assert_response :forbidden
  end

  def test_should_destroy_component_through_html
    login_as
    assert_difference('Component.count',-1) do
      delete :destroy, :page_id => pages(:one_design).id, :id => components(:one)
    end
    assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
  end

  def test_should_destroy_component_through_js
    login_as
    assert_difference('Component.count',-1) do
      xhr :post, :destroy, :page_id => pages(:one_design).id, :id => components(:one)
    end
    assert_select_rjs :remove, "component_#{components(:one).id}"
  end

  def test_shouldnt_destroy_component_without_permission
    login_with_permission
    assert_no_difference("Component.count") do
      delete :destroy, :page_id => pages(:one_design).id, :id => components(:one)
    end
    assert_response :forbidden
  end

  def test_should_show_component_form
    component_form_mock
    get :show, :page_id => pages(:one_design).id, :id => components(:one)
    assert_response :success

    assert_not_nil component = assigns(:component)
    assert_not_nil page = assigns(:page)
  end
  
  def test_shouldnt_show_component_form_without_permission
    login_with_permission
    get :show, :page_id => pages(:one_design).id, :id => components(:one)
    assert_response :forbidden
  end

  def test_should_edit_component_throught_js
    login_as
    xhr :put, :update, :page_id => pages(:one_design).id, :id => components(:one).id, :component => {:name => "Test name", :content => "Test content"}

    assert_not_nil component = assigns(:component)
    assert_equal component.reload.name, "Test name"
    assert_equal component.content, "Test content"
  end

  def test_shouldnt_destroy_component_without_permission
    login_with_permission
    xhr :put, :update, :page_id => pages(:one_design).id, :id => components(:one).id, :component => {:name => "Test name", :description => "Test description"}
    assert_response :forbidden
  end

  # TODO: We need refactorize change_order action and redo this test
  # because aren't very clean
  #def test_should_change_order
  #  login_as
  #  block_type = pages(:one_design).page_template.block_types.first
  #  block = pages(:one_design).all_blocks_as_hash[block_type.key]
  #  assert_not_equal block.id, block.block_type.id
  #  Component.update_all ["block_id = ?", block.id]
  #  assert_operator block.components.size, :>, 1
  #  original = block.components.map(&:id)
  #
  #  get :change_order, :page_id => pages(:one_design).id, "block" => {block.block_type.id => original.reverse}
  #  require 'ruby-debug';debugger
  #  assert_equal original.reverse, block.reload.components.map(&:id)
  #  assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
  #end
  
  def test_shouldnt_change_order_without_permission
    login_with_permission
    block_type = pages(:one_design).page_template.block_types.first
    block = pages(:one_design).all_blocks_as_hash[block_type.key]
    assert_not_equal block.id, block.block_type.id
    Component.update_all ["block_id = ?", block.id]
    assert_operator block.components.size, :>, 1
    original = block.components.map(&:id)

    get :change_order, :page_id => pages(:one_design).id, "block" => {block.block_type.id => original.reverse}
    assert_response :forbidden
  end

  def test_should_change_order_with_empty_blocks
    login_as
    get :change_order, :page_id => pages(:one_design).id
    assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
  end

  def test_should_change_name
    login_as
    get :change_name, :page_id => pages(:one_design).id, :id => components(:one).id, :value => "New name"
    assert_not_nil component = assigns(:component)
    assert_response :success
    assert_equal component.name, "New name"
  end
  
  def test_shouldnt_change_name_without_permission
    login_with_permission
    get :change_name, :page_id => pages(:one_design).id, :id => components(:one).id, :value => "New name"
    assert_response :forbidden
  end

end
