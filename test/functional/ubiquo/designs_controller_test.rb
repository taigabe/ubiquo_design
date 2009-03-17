require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::DesignsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_design
    login_as
    page = pages(:one)
    template_mock(page)
    get :show, :page_id => page.id
    assert_response :success
    assert_not_nil page = assigns(:page)
    assert_not_nil component_types = assigns(:component_types)
    assert page.page_template.block_types.size > 0
    page.page_template.block_types.each do |block_type|
      assert_select "#block_type_holder_#{block_type.id}"
      block = page.all_blocks_as_hash[block_type.key]

      last_order = 0
      block.components.each do |component|
        assert_operator component.position, :>, last_order
        last_order = component.position
        assert_select "#component_#{component.id}"
      end
    end
  end

  def test_should_get_design_with_permission
    login_with_permission :design_management
    get :show, :page_id => pages(:one).id
    assert_response :success
  end

  def test_should_not_get_design_without_permission
    login_with_permission 
    get :show, :page_id => pages(:one).id
    assert_response :forbidden
  end

  def test_should_show_default_form_on_available_blocks
    login_as
    page = pages(:two)
    template_mock(page)

    get :show, :page_id => page.id
    page.page_template.block_types.each do |block_type|
      assert_select "#use_default_#{block_type.id}" if block_type.can_use_default_block?
    end
  end

  def test_shouldnt_show_default_form_on_home
    page = pages(:one)
    template_mock(page)
    assert_equal page.url_name, ""
    assert page.blocks.map(&:id).sort == page.all_blocks.map(&:id).sort
    assert_not_equal page.blocks.size, 0
    assert page.blocks.map(&:block_type).map(&:can_use_default_block).include?(true)
    get :show, :page_id => page.id
    page.blocks.each do |block|
      assert_select "#use_default_#{block.block_type.id}", false
    end
  end


  def test_should_show_edit_component_with_editable_components
    login_as
    component = nil
    assert_nothing_thrown do
      component = ComponentType.find(:first, :conditions => ["is_configurable = ? or is_configurable is ?", false, nil]).components.first
      page = component.block.page
      assert_not_nil page
    end

    page = pages(:one)
    template_mock(page)
    get :show, :page_id => page.id

    assert_select "#component_#{component.id} .editar", false
  end
end
