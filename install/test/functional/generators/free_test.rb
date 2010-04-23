require File.dirname(__FILE__) + '/../../test_helper'
require 'mocha'

class FreeGeneratorTest < ActionController::TestCase
  tests PagesController

  test "free generator should run generator" do
    component, page = insert_component
    locals, render_options = run_generator(:free, component, {})
    assert_equal locals[:content], component_attributes[:content], "Error on component content"
  end

  test "content generator should get show" do
    component, page = insert_component
    get :show, :category => page.page_category.url_name, :url_name => page.url_name
    assert_response :success
    assert_select "div#example", {:count => 1, :text => 'Example content'}
   end

  private

  def component_attributes
    {
      :content => '<div id="example">Example content</div>',
    }
  end
  
  def insert_component(component_options = {}, component_type_options = {})      
    component_options.update(component_attributes)
    component_type_options.update({
      :key => "free", 
      :subclass_type => "Free"
    })
    insert_component_in_page(component_type_options, component_options)
  end

end
