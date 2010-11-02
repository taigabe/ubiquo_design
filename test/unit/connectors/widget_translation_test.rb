require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class WidgetTranslationTest < ActiveSupport::TestCase

    if Ubiquo::Plugin.registered[:ubiquo_i18n]

      def setup
        save_current_design_connector
        UbiquoDesign::Connectors::WidgetTranslation.load!
      end

      def teardown
        reload_old_design_connector
        Locale.current = nil
      end

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
        assert_equal page.is_the_published?, false
        assert_raise ActiveRecord::RecordNotFound do
          Page.published.with_url(page.url_name)
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

      test "widget_controller must set locale on the prepare widget with configurable widget" do
        widget = widgets(:one)
        widget.expects(:is_configurable?).returns(true)
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
        )
        assert_equal nil, widget.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(widget)
        assert_equal 'es', widget.locale
      end

      test "widget_controller must set locale on the prepare widget with non configurable widget" do
        widget = widgets(:one)
        widget.expects(:is_configurable?).returns(false)
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
        )
        assert_equal nil, widget.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(widget)
        assert_equal 'any', widget.locale
      end
    end

    private

    def create_page(options = {})
      Page.create({
        :name => "Custom page",
        :url_name => "custom_page",
        :page_template => "static",
        :published_id => nil,
      }.merge(options))
    end

    def save_current_design_connector
      @old_connector = UbiquoDesign::Connectors::Base.current_connector
    end

    def reload_old_design_connector
      @old_connector.load!
    end
  end
end
