require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class WidgetTranslationTest < ActiveSupport::TestCase
    # only tests that if widget_translation connector is loaded
    if  Ubiquo::Config.context(:ubiquo_design).get(:connector) == "widget_translation"
      test "widgets are translatable" do
        assert Widget.is_translatable?
      end
      
      test "create widgets migration" do
        ActiveRecord::Migration.expects(:create_table).with(:widgets, :translatable => true).once
        ActiveRecord::Migration.uhook_create_widgets_table
      end
      
      test "publication must copy widget translations and their asset relations" do
        page = create_page
        page.blocks << pages(:one).blocks
        assert_equal page.is_public?, false
        assert_equal page.is_published?, false
        assert_raise ActiveRecord::RecordNotFound do
          Page.public.find_by_url_name(page.url_name)          
        end
        widgets = page.blocks.map(&:widgets).flatten
        num_widgets = widgets.size
        assert num_widgets > 1
        widgets.each_with_index do |widget, i|
          widget.content_id = 1
          widget.locale = "loc#{i}"
          assert widget.save
        end
        assert_difference "Widget.count",num_widgets do # cloned widgets
          assert page.publish
        end
      end
      
      test "widgets_controller find widget" do
        c = widgets(:one)
        c.update_attribute :locale, 'es'
        Ubiquo::WidgetsController.any_instance.stubs(
          :params => {:id => c.id},
          :session => {:locale => 'es'}
          )
        assert_equal c, Ubiquo::WidgetsController.new.uhook_find_widget
      end
      test "widgets_controller dont find widget" do
        c = widgets(:one)
        c.update_attribute :locale, 'en'
        Ubiquo::WidgetsController.any_instance.stubs(
          :params => {:id => c.id},
          :session => {:locale => 'es'}
          )
        assert_raise ActiveRecord::RecordNotFound do
          Ubiquo::WidgetsController.new.uhook_find_widget
        end
      end
      
      test "widget_controller must set locale on the prepare widget with configurable widget" do
        c = widgets(:one)
        c.widget.update_attribute :is_configurable, true
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
          )
        assert_equal nil, c.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(c)
        assert_equal 'es', c.locale
      end
      
      test "widget_controller must set locale on the prepare widget with non configurable widget" do
        c = widgets(:one)
        c.widget.update_attribute :is_configurable, false
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
          )
        assert_equal nil, c.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(c)
        assert_equal 'any', c.locale
      end
    end

    private 
    
    def create_page(options = {})
      Page.create({
        :name => "Custom page",
        :url_name => "custom_page",
        :page_template => "static",
        :pending_publish => true,
        :published_id => nil,
      }.merge(options))
    end
  end
end
