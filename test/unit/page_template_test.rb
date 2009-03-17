require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTemplateTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_page_template
    assert_difference "PageTemplate.count" do
      page_template = create_page_template
      assert !page_template.new_record?, "#{page_template.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "PageTemplate.count" do
      page_template = create_page_template :name => ""
      assert page_template.errors.on(:name)
    end
  end

  def test_should_require_key
    assert_no_difference "PageTemplate.count" do
      page_template = create_page_template :key => ""
      assert page_template.errors.on(:key)
    end
  end
  
  def test_should_require_thumbnail
    assert_no_difference "PageTemplate.count" do
      page_template = create_page_template :thumbnail => nil
      assert page_template.errors.on(:thumbnail)
    end
  end
  
  def test_should_have_unique_key
    assert_difference "PageTemplate.count", 1 do
      page_template1 = create_page_template :key => "unique_key"
      page_template2 = create_page_template :key => "unique_key"
      
      assert !page_template1.new_record?, "#{page_template1.errors.full_messages.to_sentence}"
      assert page_template2.errors.on(:key)
    end
  end
  
  def test_can_navigate_to_component_types
    assert_nothing_raised do
      page_templates(:one).component_types
    end    
  end

  private

  def create_page_template(options = {})
    PageTemplate.create({:name => "Index page", :key => "index", :thumbnail => test_file}.merge!(options))
  end

end
