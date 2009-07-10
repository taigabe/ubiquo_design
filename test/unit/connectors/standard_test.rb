require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class StandardTest < ActiveSupport::TestCase
    test "should publish components" do
      page = create_page :page_template_id => page_templates(:one).id
      page.blocks << pages(:one).blocks
      assert_equal page.is_public?, false
      assert_equal page.is_published?, false
      assert_raises ActiveRecord::RecordNotFound do
        Page.find_public(page.page_category.url_name, page.url_name)
      end
      num_components = page.blocks.map(&:components).flatten.size
      assert num_components > 0
      assert_difference "Component.count",num_components do # cloned components
        assert page.publish
      end
    end
    
    test "should load public page" do 
      p = pages(:one_design)
      PagesController.any_instance.stubs(:params => {:category => p.page_category.url_name, :url_name => p.url_name})
      assert_equal pages(:one), PagesController.new.uhook_load_page
    end
    
    test "components_controller find component" do
      c = components(:one)
      Ubiquo::ComponentsController.any_instance.stubs(:params => {:id => c.id})
      assert_equal c, Ubiquo::ComponentsController.new.uhook_find_component
    end
    
    test "components_controller destroy component" do
      assert_difference "Component.count", -1 do
        assert Ubiquo::ComponentsController.new.uhook_destroy_component(components(:one))
      end
    end
    
    test "components_controller update component" do
      c = components(:one)
      Ubiquo::ComponentsController.any_instance.stubs(:params => {:id => c.id, :component => {:name => "test"}})
      assert_equal "test", Ubiquo::ComponentsController.new.uhook_update_component.name
    end
    
    test "menu_items_controller find menu items" do 
      assert_equal MenuItem.all.select{|mi|mi.is_root?}, Ubiquo::MenuItemsController.new.uhook_find_menu_items
    end
    
    test "menu_items_controller new menu item without parent" do 
      Ubiquo::MenuItemsController.any_instance.stubs(:params => {})
      mi = Ubiquo::MenuItemsController.new.uhook_new_menu_item
      assert_equal 0, mi.parent_id
      assert mi.new_record?
    end
    
    test "menu_items_controller new menu item with parent" do 
      Ubiquo::MenuItemsController.any_instance.stubs(:params => {:parent_id => 2})
      mi = Ubiquo::MenuItemsController.new.uhook_new_menu_item
      assert_equal 2, mi.parent_id
      assert mi.new_record?
    end
    
    test "menu_items_controller create menu item" do
      options = { 
        :caption => "Caption", 
        :url => "http://www.gnuine.com", 
        :description => "Gnuine webpage",
        :is_linkable => true,
        :parent_id => 0,
        :position => 0,
        :automatic_menu_id => nil,
      }
      Ubiquo::MenuItemsController.any_instance.stubs(:params => {:menu_item => options})
      assert_difference "MenuItem.count" do
        mi = Ubiquo::MenuItemsController.new.uhook_create_menu_item
      end
    end
    
    test "menu_items_controller destroy menu item" do 
      assert_difference "MenuItem.count", -1 do 
        Ubiquo::MenuItemsController.new.uhook_destroy_menu_item(menu_items(:one))
      end
    end
    
    test "menu_items_controller load automatic menus" do 
       assert_equal_set AutomaticMenu.all, Ubiquo::MenuItemsController.new.uhook_load_automatic_menus
    end
    
    private 
    
    def create_page(options = {})
      Page.create({:name => "Custom page",
          :url_name => "custom_page",
          :page_template_id => page_templates(:one).id,
          :page_category_id => page_categories(:one).id,
          :page_type_id => page_types(:one).id,
          :is_public => false,
        }.merge(options))
    end
  end
end
