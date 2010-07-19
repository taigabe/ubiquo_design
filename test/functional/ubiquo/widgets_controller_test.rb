require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::WidgetsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_add_widget_through_html
    login_as
    assert_difference('Widget.count') do
      post :create, :page_id => pages(:one_design).id, :block => pages(:one_design).blocks.first, :widget => widgets(:one).class.to_s
    end
    assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
    widget = assigns(:widget)
    assert_not_nil widget
    assert_equal widget.block, pages(:one_design).blocks.first
    assert_equal widget.key, widgets(:one).key
    assert_equal widget.name, Widget.default_name_for(widgets(:one).key)
  end

  def test_should_add_editable_widget_through_js
    login_as
    assert_not_nil editable_widget = pages(:one_design).available_widgets
    assert_not_nil not_editable_widget = pages(:one_design).available_widgets.select{|widget| widget.configurable?} # TODO this or similar
    [editable_widget, not_editable_widget].each do |widget|
      assert_difference('Widget.count') do
        xhr :post, :create, :page_id => pages(:one_design).id, :block => pages(:one_design).blocks.first, :widget => widget
      end
      widget = assigns(:widget)
      assert_not_nil widget
      assert widget.block == pages(:one_design).blocks.first
      assert widget.widget == widget

      assert_select_rjs :insert_html, "block_type_holder_#{widget.block.block_type.id}" do
        assert_select "#widget_name_field_#{widget.id}"
      end
      edition_matches = @response.body.match(/myLightWindow\._processLink\(\$\(\'edit_widget_#{widget.id}\'\)\)\;/)
      assert_equal edition_matches.nil?, !widget.widget.is_configurable?

    end
  end

  def test_shouldnt_add_widget_without_permission
    login_with_permission
    assert_no_difference("Widget.count") do
      post :create, :page_id => pages(:one_design).id, :block => pages(:one).blocks.first, :widget => widgets(:one)
    end
    assert_response :forbidden
  end

  def test_should_destroy_widget_through_html
    login_as
    assert_difference('Widget.count',-1) do
      delete :destroy, :page_id => pages(:one_design).id, :id => widgets(:one)
    end
    assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
  end

  def test_should_destroy_widget_through_js
    login_as
    assert_difference('Widget.count',-1) do
      xhr :post, :destroy, :page_id => pages(:one_design).id, :id => widgets(:one)
    end
    assert_select_rjs :remove, "widget_#{widgets(:one).id}"
  end

  def test_shouldnt_destroy_widget_without_permission
    login_with_permission
    assert_no_difference("Widget.count") do
      delete :destroy, :page_id => pages(:one_design).id, :id => widgets(:one)
    end
    assert_response :forbidden
  end

  def test_should_show_widget_form
    widget_form_mock
    get :show, :page_id => pages(:one_design).id, :id => widgets(:one)
    assert_response :success

    assert_not_nil widget = assigns(:widget)
    assert_not_nil page = assigns(:page)
  end
  
  def test_shouldnt_show_widget_form_without_permission
    login_with_permission
    get :show, :page_id => pages(:one_design).id, :id => widgets(:one)
    assert_response :forbidden
  end

  def test_should_edit_widget_throught_js
    login_as
    xhr :put, :update, :page_id => pages(:one_design).id, :id => widgets(:one).id, :widget => {:name => "Test name", :content => "Test content"}

    assert_not_nil widget = assigns(:widget)
    assert_equal widget.reload.name, "Test name"
    assert_equal widget.content, "Test content"
  end

  def test_shouldnt_destroy_widget_without_permission
    login_with_permission
    xhr :put, :update, :page_id => pages(:one_design).id, :id => widgets(:one).id, :widget => {:name => "Test name", :description => "Test description"}
    assert_response :forbidden
  end

  # TODO: We need refactorize change_order action and redo this test
  # because aren't very clean
  #def test_should_change_order
  #  login_as
  #  block_type = pages(:one_design).page_template.block_types.first
  #  block = pages(:one_design).all_blocks_as_hash[block_type.key]
  #  assert_not_equal block.id, block.block_type.id
  #  Widget.update_all ["block_id = ?", block.id]
  #  assert_operator block.widgets.size, :>, 1
  #  original = block.widgets.map(&:id)
  #
  #  get :change_order, :page_id => pages(:one_design).id, "block" => {block.block_type.id => original.reverse}
  #  require 'ruby-debug';debugger
  #  assert_equal original.reverse, block.reload.widgets.map(&:id)
  #  assert_redirected_to(ubiquo_page_design_path(pages(:one_design)))
  #end
  
  def test_shouldnt_change_order_without_permission
    login_with_permission
    block_type = Page.blocks(pages(:one_design).page_template).first
    block = pages(:one_design).all_blocks_as_hash[block_type]
    assert_not_equal block.id, block.block_type.id
    Widget.update_all ["block_id = ?", block.id]
    assert_operator block.widgets.size, :>, 1
    original = block.widgets.map(&:id)

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
    get :change_name, :page_id => pages(:one_design).id, :id => widgets(:one).id, :value => "New name"
    assert_not_nil widget = assigns(:widget)
    assert_response :success
    assert_equal widget.name, "New name"
  end
  
  def test_shouldnt_change_name_without_permission
    login_with_permission
    get :change_name, :page_id => pages(:one_design).id, :id => widgets(:one).id, :value => "New name"
    assert_response :forbidden
  end

end
