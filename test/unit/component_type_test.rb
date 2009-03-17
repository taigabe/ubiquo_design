require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class ComponentTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_component_type
    assert_difference "ComponentType.count" do
      component_type = create_component_type
      assert !component_type.new_record?, "#{component_type.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "ComponentType.count" do
      component_type = create_component_type :name => ""
      assert component_type.errors.on(:name)
    end
  end

    def test_should_require_key
      assert_no_difference "ComponentType.count" do
        component_type = create_component_type :key => ""
        assert component_type.errors.on(:key)
      end
    end
    

    def test_should_require_subclass_type
      assert_no_difference "ComponentType.count" do
        component_type = create_component_type :subclass_type => ""
        assert component_type.errors.on(:subclass_type)
      end
    end
  
  def test_should_have_unique_key
    assert_difference "ComponentType.count", 1 do
      component_type1 = create_component_type :key => "unique_key"
      component_type2 = create_component_type :key => "unique_key"
      
      assert !component_type1.new_record?, "#{component_type1.errors.full_messages.to_sentence}"
      assert component_type2.errors.on(:key)
    end
  end
  
  private
  def create_component_type(options = {})
    ComponentType.create({:name => "Generator A", :key => "gen_a", :subclass_type => "TestComponent", :is_configurable => false}.merge!(options))
  end
end
