require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class BlockTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_block_type
    assert_difference "BlockType.count" do
      block_type = create_block_type
      assert !block_type.new_record?, "#{block_type.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "BlockType.count" do
      block_type = create_block_type :name => ""
      assert block_type.errors.on(:name)
    end
  end

  def test_should_require_key
    assert_no_difference "BlockType.count" do
      block_type = create_block_type :key => ""
      assert block_type.errors.on(:key)
    end
  end

  def test_should_have_unique_key
    assert_difference "BlockType.count", 1 do
      block_type1 = create_block_type :key => "unique_key"
      block_type2 = create_block_type :key => "unique_key"

      assert !block_type1.new_record?, "#{block_type1.errors.full_messages.to_sentence}"
      assert block_type2.errors.on(:key)
    end
  end


  private
  def create_block_type(options = {})
    BlockType.create({:name => "New block type", :key => "new_block_type"}.merge!(options))
  end
end
