require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTemplateBlockTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_page_template_block_type
    assert_difference "PageTemplateBlockType.count" do
      page_template_block_type = create_page_template_block_type
      assert !page_template_block_type.new_record?, "#{page_template_block_type.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_page_template
    assert_no_difference "PageTemplateBlockType.count" do
      page_template_block_type = create_page_template_block_type :page_template_id => nil
      assert page_template_block_type.errors.on(:page_template)
    end    
  end
  
  def test_should_require_block_type
    assert_no_difference "PageTemplateBlockType.count" do
      page_template_block_type = create_page_template_block_type :block_type_id => nil
      assert page_template_block_type.errors.on(:block_type)
    end    
  end
  
  def test_shouldnt_accept_duplicated_pairs
    assert_difference "PageTemplateBlockType.count", 1 do
      page_template_block_type1 = create_page_template_block_type
      page_template_block_type2 = create_page_template_block_type
      
      assert !page_template_block_type1.new_record?, "#{page_template_block_type1.errors.full_messages.to_sentence}"
      assert !page_template_block_type2.errors.blank?
    end
  end
  
  private
  def create_page_template_block_type(options = {})
    PageTemplateBlockType.create({:page_template_id => page_templates(:two).id, :block_type_id => block_types(:two).id}.merge!(options))
  end
end
