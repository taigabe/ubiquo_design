require File.dirname(__FILE__) + '/../test_helper'

class GenericDetailWidgetTest < ActionController::TestCase
  tests PagesController
  
  test "should render" do
    widget, page = create_widget(:generic_detail)
    
    old_proc_behaviour = ::Widget.behaviours[widget.key][:proc]
    ::Widget.behaviours[widget.key][:proc] = Proc.new do 
      render :text => "<div id=\"widget-test-container\">Foo</div>"
    end
    
    get :show, :url => [page.url_name, widget.id]
    assert_equal @controller.widget_rendered?, true
    assert_select "#widget-test-container", "Foo"
    
    ::Widget.behaviours[widget.key][:proc] = old_proc_behaviour
  end
  
  test "should redirect" do
    widget, page = create_widget(:generic_detail)
    page.add_widget(page.blocks.first.block_type, Free.new(:name => 'free2', :content => 'test_content'))

    PagesController.any_instance.expects(:widget_redirected?).returns(true)
    PagesController.any_instance.expects(:run_behaviour).once
    PagesController.any_instance.expects(:render).returns("foo")

    get :show, :url => [page.url_name, widget.id]
  end
  
  private

  def widget_attributes
    {
      :model => 'GenericDetail'
    }
  end

  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
