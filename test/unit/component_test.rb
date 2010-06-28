require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class ComponentTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_component
    assert_difference "Component.count" do
      component = create_sub_component
      assert !component.new_record?, "#{component.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_block
    assert_no_difference "Component.count" do
      component = create_sub_component :block_id => nil
      assert component.errors.on(:block)
    end
  end

  def test_should_require_name
    assert_no_difference "Component.count" do
      component = create_sub_component :name => nil
      assert component.errors.on(:name)
    end
  end

  def test_should_require_widget
    assert_no_difference "Component.count" do
      component = create_sub_component :widget_id => nil
      assert component.errors.on(:widget)
    end
  end

  def test_should_auto_increment_position
    assert_difference "Component.count", 2 do
      component = create_sub_component :position => nil
      assert !component.new_record?, "#{component.errors.full_messages.to_sentence}"
      assert_not_equal component.position, nil
      position = component.position
      component = create_sub_component
      assert !component.new_record?, "#{component.errors.full_messages.to_sentence}"
      assert_equal component.position, position+1
    end
  end

  def test_should_create_options_for_children
    assert_difference "Component.count",2 do
      #CREATION
      component = create_sub_component
      assert !component.new_record?, "#{component.errors.full_messages.to_sentence}"
      assert component.respond_to?(:title)
      assert component.respond_to?(:description)

      #CREATION WITH OPTIONS
      component = create_sub_component :title => "title", :description => "desc"
      assert !component.new_record?, "#{component.errors.full_messages.to_sentence}"
      assert component.title === "title"
      assert component.description === "desc"

      #FINDING
      component = Component.find(component.id)
      assert component.title === "title"
      assert component.description === "desc"

      #MODIFY
      component.title = "new title"
      assert component.save
      assert Component.find(component.id).title === "new title"
    end
  end

  def test_should_set_is_modified_attribute_for_page_on_component_update
    component = components(:one)
    page = component.block.page
    assert !page.reload.is_modified?
    assert component.save
    assert page.reload.is_modified?
  end

  def test_should_set_is_modified_attribute_for_page_on_component_delete
    component = components(:one)
    page = component.block.page
    assert !page.reload.is_modified?
    assert component.destroy
    assert page.reload.is_modified?
  end


  private
  def create_sub_component(options = {})
    SubComponent.create({:block_id => blocks(:one).id, :widget_id => widgets(:one).id, :name => "name"}.merge!(options))
  end
end

class SubComponent < Component
  self.allowed_options = :title, :description
end
