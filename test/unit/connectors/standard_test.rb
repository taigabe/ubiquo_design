require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class StandardTest < ActiveSupport::TestCase
    def setup
      UbiquoDesign::Connectors::Standard.load!
    end
    
    test "should publish components" do
      page = create_page :page_template_id => page_templates(:one).id
      page.blocks << pages(:one).blocks
      assert page.pending_publish?
      assert !page.is_published?
      assert_nil Page.published.find_by_url_name(page.url_name)
      num_components = page.blocks.map(&:components).flatten.size
      assert num_components > 0
      assert_difference "Component.count",num_components do # cloned components
        assert page.publish
      end
    end
    
    test "should load public page" do 
      p = pages(:one_design)
      PagesController.any_instance.stubs(:params => { :url_name => p.url_name })
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
      assert_equal_set MenuItem.all.select{|mi|mi.is_root?}, Ubiquo::MenuItemsController.new.uhook_find_menu_items
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
      mi = menu_items(:one)
      assert_difference "MenuItem.count", -1*(1+mi.children.size) do 
        Ubiquo::MenuItemsController.new.uhook_destroy_menu_item(mi)
      end
    end
    
    test "menu_items_controller load automatic menus" do 
       assert_equal_set AutomaticMenu.all, Ubiquo::MenuItemsController.new.uhook_load_automatic_menus
    end
    
    test "ubiquo pages_controller find pages" do
      searched_pages = Ubiquo::PagesController.new.uhook_find_private_pages({}, 'name', 'asc')
      fixture_pages = [pages(:one_design), pages(:two_design),
                       pages(:only_menu_design), pages(:test_page)]
require 'ruby-debug';debugger      
assert_equal searched_pages.size, 4
      assert_equal_set fixture_pages, searched_pages
    end
    
    test "ubiquo pages_controller new page" do 
      assert Ubiquo::PagesController.new.uhook_new_page.new_record?
    end

    test "ubiquo pages_controller create page" do 
      attributes = create_page.attributes
      attributes[:url_name] = "test"
      Ubiquo::PagesController.any_instance.stubs(:params => {:page => attributes})
      p = nil
      assert_difference "Page.count" do 
        p = Ubiquo::PagesController.new.uhook_create_page
      end
      assert !p.new_record?, p.errors.full_messages.to_sentence
    end
    
    test "ubiquo pages_controller update page" do 
      page = create_page
      attributes = page.attributes
      attributes[:name] = "test"
      Ubiquo::PagesController.any_instance.stubs(:params => {:page => attributes})
      Ubiquo::PagesController.new.uhook_update_page(page)
      assert_equal "test", page.reload.name
    end
    
    test "ubiquo pages_controller destroy page" do 
      page = create_page
      assert_difference "Page.count", -1 do 
        Ubiquo::PagesController.new.uhook_destroy_page(page)
      end
    end
    
    test "create page migration" do
      ActiveRecord::Migration.expects(:create_table).with(:pages).once
      ActiveRecord::Migration.uhook_create_pages_table
    end

    test "create components migration" do
      ActiveRecord::Migration.expects(:create_table).with(:components).once
      ActiveRecord::Migration.uhook_create_components_table
    end
    
    private 
    
    def create_page(options = {})
      Page.create({
        :name => "Custom page",
        :url_name => "custom_page",
        :page_template_id => page_templates(:one).id,
        :published_id => nil,
      }.merge(options))
    end
  end
end
