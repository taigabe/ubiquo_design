require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class BlockTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_block
    assert_difference "Block.count" do
      block = create_block
      assert !block.new_record?, "#{block.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_block_type
    assert_no_difference "Block.count" do
      block = create_block :block_type_id => nil
      assert block.errors.on(:block_type)
    end    
  end

  def test_should_require_page_id
    assert_no_difference "Block.count" do
      block = create_block :page_id => nil
      assert block.errors.on(:page)
    end    
  end
  
  def test_create_for_block_type_and_page
    assert_difference "Block.count" do
      block = Block.create_for_block_type_and_page(block_types(:one), pages(:one))
      assert_equal block.page, pages(:one)
      assert_equal block.block_type, block_types(:one)
    end
  end

  def test_should_set_is_modified_attribute_for_page_on_block_update
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page(block_types(:one), page)
    assert page.reload.is_modified?
    page.publish
    assert !page.reload.is_modified?
    assert block.save
    assert page.reload.is_modified?
  end

  def test_should_set_is_modified_attribute_for_page_on_block_delete
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page(block_types(:one), page)
    assert page.reload.is_modified?
    page.publish
    assert !page.reload.is_modified?
    assert block.destroy
    assert page.reload.is_modified?
  end
  
  
  private
  
  def create_block(options = {})
    Block.create({:block_type_id => block_types(:one).id, :page_id => pages(:one).id}.merge!(options))
  end
end
