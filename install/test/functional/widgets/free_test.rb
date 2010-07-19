require File.dirname(__FILE__) + '/../../test_helper'
require 'mocha'

class FreeGeneratorTest < ActionController::TestCase
  tests PagesController

  test "free widget should run behaviour" do
    widget, page = create_widget(:free)
    run_behaviour(widget)
    assert_equal widget_attributes[:content], assigns(:content), "Error on widget content"
  end

  test "content generator should get show" do
    widget, page = create_widget(:free)
    get :show, :url => page.url_name
    assert_response :success
    assert_select "div#example", {:count => 1, :text => 'Example content'}
   end

  private

  def widget_attributes
    {
      :content => '<div id="example">Example content</div>',
    }
  end

  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
