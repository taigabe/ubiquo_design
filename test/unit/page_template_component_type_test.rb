require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTemplateComponentTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_page_template_component_type
    assert_difference "PageTemplateComponentType.count" do
      page_template_component_type = create_page_template_component_type
      assert !page_template_component_type.new_record?, "#{page_template_component_type.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_page_template
    assert_no_difference "PageTemplateComponentType.count" do
      page_template_component_type = create_page_template_component_type :page_template_id => nil
      assert page_template_component_type.errors.on(:page_template)
    end    
  end
  
  def test_should_require_component_type
    assert_no_difference "PageTemplateComponentType.count" do
      page_template_component_type = create_page_template_component_type :component_type_id => nil
      assert page_template_component_type.errors.on(:component_type)
    end    
  end
  
  def test_shouldnt_accept_duplicated_pairs
    assert_difference "PageTemplateComponentType.count", 1 do
      page_template_component_type1 = create_page_template_component_type
      page_template_component_type2 = create_page_template_component_type
      
      assert !page_template_component_type1.new_record?, "#{page_template_component_type1.errors.full_messages.to_sentence}"
      assert !page_template_component_type2.errors.blank?
    end
  end
  
  private
  def create_page_template_component_type(options = {})
    default_options = {
      :page_template_id => page_templates(:menu).id, 
      :component_type_id => component_types(:one).id
    }
    PageTemplateComponentType.create(default_options.merge(options))
  end
end
