module UbiquoDesign
  module Extensions
    module TestHelper
      def component_form_mock
        def @controller.render_component_form(*args)
          render :inline => "Hi"
        end
      end
      
      def template_mock(page)
        def @controller.render_template_file(*args)
          template_file = File.join(ActiveSupport::TestCase.fixture_path, "templates", "test", "public.html.erb")
          render :file => template_file
        end
        @controller.class.send(:define_method, :render_page_to_string) do
          render_to_string :file => File.join(ActiveSupport::TestCase.fixture_path, "templates", "test", "ubiquo.html.erb"), :locals => {:page => page}
        end
      end
      
      def run_generator(name, component, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", component, options)
      end
      
      def run_menu_generator(name, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", options)
      end

      # Create a component type for testing
      #
      # To create a component, we need the component_type_options,  the component_options
      # and an array of component_params options.
      # 
      # A page and a block are created on-the-fly, so there is no need to create fixtures
      # for each component (a difficult task)
      #
      # You can disable component validation (useful to test new component forms
      #
      def insert_component_in_page(component_type_options, component_options, component_params = [], validate = true)
        ComponentType.delete_all
        component_type_options.reverse_merge!(
                                              :name => 'TestComponentType', 
                                              :is_configurable => false)
        component, page = create_test_page(component_type_options, component_options, component_params)            
        if validate
          assert component.save, "Component has errors (attributes: #{component.options.inspect})"
        else
          component.save_without_validation!
        end
        [component, page]
      end    

      def create_test_page(component_type_options, component_options, component_params)
        component_type = ComponentType.create!(component_type_options)
        component_options.reverse_merge!(
                                         :component_type => component_type,
                                         :name => 'TestComponent')
        component_params.each do |cp_attributes|
          component_type.component_params << ComponentParam.new(cp_attributes)
        end
        component_model = component_type_options[:subclass_type].constantize
        component = component_model.new(component_options)
        thumbnail_template = Tempfile.new("template1.png")
        page_template = PageTemplate.create!(:name => "Test template", 
                                             :key => 'test', 
                                             :thumbnail => thumbnail_template)
        block_type = BlockType.create!(:name => 'Block Type Test', :key => 'block_test')
        block = Block.new(:block_type => block_type)
        
        default_page_options = {
          :name => 'Test page', 
          :url_name => 'test_page',
          :page_template => page_template, 
          :is_public => true,
        }
        page = Page.create!(default_page_options)
        component.block = block 
        page.blocks << block
        [component, page]
      end
    end
  end
end
