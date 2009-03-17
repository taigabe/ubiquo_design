require File.dirname(__FILE__) + '/../test_helper'

class FreeTest < ActiveSupport::TestCase
  
  def test_should_create_free
    assert_difference 'Free.count' do
      free = create_free
      assert !free.new_record?, "#{free.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_content
    assert_no_difference 'Free.count' do
      free = create_free(:content => nil)
      assert free.errors.on(:content)
    end
  end

  private
    
  def create_free(options = {}, component_type_options = {})
    ComponentType.delete_all
    component_type_options.reverse_merge!({
      :name => "Test free",
      :key => "free", 
      :subclass_type => "Free",
    })  
    component_type = ComponentType.create!(component_type_options)
    
    default_options = {
      :name => "Test free", 
      :content => 'Content example',
      :block => blocks(:one),
      :component_type => component_type,      
    }
    Free.create(default_options.merge(options))
  end
end
