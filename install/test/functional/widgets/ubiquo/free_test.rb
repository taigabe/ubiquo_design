require File.dirname(__FILE__) + '/../../../test_helper'

class FreeGeneratorUbiquoTest < ActionController::TestCase
  tests Ubiquo::ComponentsController

  test "edit new form" do
    login_as
    component, page = insert_component({}, {}, false)
    get :show, :page_id => page.id, 
               :id => component.id
    assert_response :success
  end
  
  test "edit form" do
    login_as
    component, page = insert_component(component_attributes)
    get :show, :page_id => page.id, 
               :id => component.id
    assert_response :success
  end

  test "form submit" do
    login_as
    component, page = insert_component(component_attributes)
    xhr :post, :update, :page_id => page.id, 
                        :id => component.id, 
                        :component => component_attributes
    assert_response :success
  end

  test "form submit with errors" do
    login_as
    component, page = insert_component({}, {}, false)
    xhr :post, :update, :page_id => page.id, 
                        :id => component.id, 
                        :component => {}
    assert_response :success
    assert_select_rjs "error_messages"
  end

  private

  def component_attributes
    {
      :content => 'Example content',
    }
  end
  
  def insert_component(component_options = {}, widget_options = {}, validation = true)
    widget_options.reverse_merge!({
      :key => "free", 
      :subclass_type => "Free"
    })
    insert_component_in_page(widget_options, component_options, [], validation)      
  end
         
end
