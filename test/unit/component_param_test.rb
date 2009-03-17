require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class ComponentParamTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_component_params
    assert_difference "ComponentParam.count", +1 do
      component_param = create_component_param
      assert !component_param.new_record?, "#{component_param.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_require_name
    assert_no_difference "ComponentParam.count" do
      component_param = create_component_param :name => ""
      assert component_param.errors.on(:name)
    end
  end  

  def test_should_require_is_required
    assert_no_difference "ComponentParam.count" do
      component_param = create_component_param :is_required => nil
      assert component_param.errors.on(:is_required)
    end
  end  

  def test_should_require_component_type_id
    assert_no_difference "ComponentParam.count" do
      component_param = create_component_param :component_type_id => nil
      assert component_param.errors.on(:component_type_id)
    end
  end

  def test_should_require_uniqueness_of_name
    component_param = create_component_param :name => "test"
    assert_no_difference "PageType.count" do
      component_param = create_component_param :name => "test"
      assert component_param.errors.on(:name)
    end
  end

  private
  
  def create_component_param(options = {})
    default_options = {
      :name => 'default_name',
      :is_required => false,
      :component_type_id => component_types(:one).id,
    }
    ComponentParam.create(default_options.merge(options))
  end
end
