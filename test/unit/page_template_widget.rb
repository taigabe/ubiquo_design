require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTemplateWidgetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_page_template_widget
    assert_difference "PageTemplateWidget.count" do
      page_template_widget = create_page_template_widget
      assert !page_template_widget.new_record?, "#{page_template_widget.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_page_template
    assert_no_difference "PageTemplateWidget.count" do
      page_template_widget = create_page_template_widget :page_template_id => nil
      assert page_template_widget.errors.on(:page_template)
    end    
  end
  
  def test_should_require_widget
    assert_no_difference "PageTemplateWidget.count" do
      page_template_widget = create_page_template_widget :widget_id => nil
      assert page_template_widget.errors.on(:widget)
    end    
  end
  
  def test_shouldnt_accept_duplicated_pairs
    assert_difference "PageTemplateWidget.count", 1 do
      page_template_widget1 = create_page_template_widget
      page_template_widget2 = create_page_template_widget
      
      assert !page_template_widget1.new_record?, "#{page_template_widget1.errors.full_messages.to_sentence}"
      assert !page_template_widget2.errors.blank?
    end
  end
  
  private
  def create_page_template_widget(options = {})
    default_options = {
      :page_template_id => page_templates(:menu).id, 
      :widget_id => widgets(:one).id
    }
    PageTemplateWidget.create(default_options.merge(options))
  end
end
