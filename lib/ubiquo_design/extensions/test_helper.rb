module UbiquoDesign
  module Extensions
    module TestHelper
      def widget_form_mock
        def @controller.render_widget_form(*args)
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
      
      def run_generator(name, widget, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", widget, options)
      end
      
      def run_menu_generator(name, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", options)
      end

      # Create a widget type for testing
      #
      # To create a widget, we need the widget_options and the widget_options
      # 
      # A page and a block are created on-the-fly, so there is no need to create fixtures
      # for each widget (a difficult task)
      #
      # You can disable widget validation (useful to test new widget forms
      #
      def insert_widget_in_page(widget_options, temp_options, validate = true)
        Widget.delete_all
        widget_options.reverse_merge!(:name => 'TestWidget', :is_configurable => false)
        widget, page = create_test_page(widget_options, widget_options)
        if validate
          assert widget.save, "Widget has errors (attributes: #{widget.options.inspect})"
        else
          widget.save_without_validation!
        end
        [widget, page]
      end    

      def create_test_page(widget_options, temp_options)
        widget = Widget.create!(widget_options)
        widget_options.reverse_merge!(
                                         :widget => widget,
                                         :name => 'TestWidget')
        widget_model = widget_options[:subclass_type].constantize
        widget = widget_model.new(widget_options)
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
          :published_id => nil,
        }
        page = Page.create!(default_page_options)
        widget.block = block
        page.blocks << block
        [widget, page]
      end
    end
  end
end
