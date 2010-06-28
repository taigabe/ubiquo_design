require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class WidgetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_widget
    assert_difference "Widget.count" do
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Widget.count" do
      widget = create_widget :name => ""
      assert widget.errors.on(:name)
    end
  end

    def test_should_require_key
      assert_no_difference "Widget.count" do
        widget = create_widget :key => ""
        assert widget.errors.on(:key)
      end
    end
    

    def test_should_require_subclass_type
      assert_no_difference "Widget.count" do
        widget = create_widget :subclass_type => ""
        assert widget.errors.on(:subclass_type)
      end
    end
  
  def test_should_have_unique_key
    assert_difference "Widget.count", 1 do
      widget1 = create_widget :key => "unique_key"
      widget2 = create_widget :key => "unique_key"
      
      assert !widget1.new_record?, "#{widget1.errors.full_messages.to_sentence}"
      assert widget2.errors.on(:key)
    end
  end
  
  private
  def create_widget(options = {})
    Widget.create({:name => "Generator A", :key => "gen_a", :subclass_type => "TestComponent", :is_configurable => false}.merge!(options))
  end
end
