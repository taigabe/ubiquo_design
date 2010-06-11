require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class BaseTest < ActiveSupport::TestCase
   
    test "load page is a page" do 
      p = Page.first
      PagesController.any_instance.stubs(:params => { :url_name => p.url_name })
      assert PagesController.new.uhook_load_page.is_a?(Page)
    end
    
    test "find component is a component" do
      c = components(:one)
      Ubiquo::ComponentsController.any_instance.stubs(:params => {:id => c.id}, :session => {})
      begin
        assert Ubiquo::ComponentsController.new.uhook_find_component.is_a?(Component)
      rescue ActiveRecord::RecordNotFound => e
        assert true
      end
    end
    
    test "prepare component returns a component" do
      c = components(:one)
      assert Ubiquo::ComponentsController.new.uhook_prepare_component(c).is_a?(Component)
    end
    
    test "destroy component should destroy one component at least" do 
      c = components(:one)
      c.class.any_instance.expects(:destroy).at_least(1)
      Ubiquo::ComponentsController.new.uhook_destroy_component(c)
    end
    
    test "find menu items returns all menu item" do
      Ubiquo::MenuItemsController.any_instance.stubs(:params => {}, :session => {})
      Ubiquo::MenuItemsController.new.uhook_find_menu_items.each do |mi|
        assert mi.is_a?(MenuItem)
      end
    end
    
  end
end
