require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class ComponentTranslationTest < ActiveSupport::TestCase
    def setup
      UbiquoDesign::Connectors::ComponentTranslation.load!
    end
    
    def teardown
      UbiquoDesign::Connectors::Standard.load!
    end
    
    test "components are translatable" do 
      assert Component.is_translatable?
    end
    
    test "create components migration" do
      ActiveRecord::Migration.expects(:create_table).with(:components, :translatable => true).once
      ActiveRecord::Migration.uhook_create_components_table
    end
    
    test "publication must copy component translations and their asset relations" do
      page = create_page :page_template_id => page_templates(:one).id
      page.blocks << pages(:one).blocks
      assert_equal page.is_public?, false
      assert_equal page.is_published?, false
      assert_raises ActiveRecord::RecordNotFound do
        Page.find_public(page.page_category.url_name, page.url_name)
      end
      components = page.blocks.map(&:components).flatten
      num_components = components.size
      assert num_components > 1
      components.each_with_index do |component, i|
        component.content_id = 1
        component.locale = "loc#{i}"
        assert component.save
      end
      assert_difference "Component.count",num_components do # cloned components
        assert page.publish
      end
    end
    
    test "components_controller find component" do
      c = components(:one)
      c.update_attribute :locale, 'es'
      Ubiquo::ComponentsController.any_instance.stubs(
        :params => {:id => c.id},
        :session => {:locale => 'es'}
        )
      assert_equal c, Ubiquo::ComponentsController.new.uhook_find_component
    end
    test "components_controller dont find component" do
      c = components(:one)
      c.update_attribute :locale, 'en'
      Ubiquo::ComponentsController.any_instance.stubs(
        :params => {:id => c.id},
        :session => {:locale => 'es'}
        )
      assert_raise ActiveRecord::RecordNotFound do
        Ubiquo::ComponentsController.new.uhook_find_component
      end
    end
    
    test "component_controller must set locale on the prepare component with configurable component" do 
      c = components(:one)
      c.component_type.update_attribute :is_configurable, true
      Ubiquo::ComponentsController.any_instance.stubs(
        :session => {:locale => 'es'},
        :params => {}
        )
      assert_equal nil, c.locale
      Ubiquo::ComponentsController.new.uhook_prepare_component(c)
      assert_equal 'es', c.locale
    end
    
    test "component_controller must set locale on the prepare component with non configurable component" do 
      c = components(:one)
      c.component_type.update_attribute :is_configurable, false
      Ubiquo::ComponentsController.any_instance.stubs(
        :session => {:locale => 'es'},
        :params => {}
        )
      assert_equal nil, c.locale
      Ubiquo::ComponentsController.new.uhook_prepare_component(c)
      assert_equal 'any', c.locale
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
