require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::DesignsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_design
    login_as
    page = pages(:one_design)
    template_mock(page)
    get :show, :page_id => page.id
    assert_response :success
    assert_not_nil page = assigns(:page)
    assert page.blocks.size > 0
    page.blocks.map(&:block_type).each do |block_type|
      assert_select "#block_type_holder_#{block_type}"
      # TODO: We going to change default blocks way.
      # We need check over this when we changed it.
      block = page.blocks.first(:conditions => { :block_type => block_type })
      #
      last_order = 0
      block.widgets.each do |widget|
        assert_operator widget.position, :>, last_order
        last_order = widget.position
      
        assert_select "#widget_#{widget.id}"
      end
    end
  end

  def test_should_get_design_with_permission
    login_with_permission :design_management
    get :show, :page_id => pages(:one_design).id
    assert_response :success
  end

  def test_should_not_get_design_without_permission
    login_with_permission 
    get :show, :page_id => pages(:one_design).id
    assert_response :forbidden
  end

  def test_should_show_edit_widget_with_editable_widgets
    login_as
    widget = nil
    assert_nothing_thrown do
      widget = widgets(:one)
      page = widget.block.page
      assert_not_nil page
    end

    page = pages(:one_design)
    template_mock(page)
    get :show, :page_id => page.id

    assert_select "#widget_#{widget.id} .editar", false
  end
end
