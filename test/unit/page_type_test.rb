require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_page_type
    assert_difference "PageType.count", +1 do
      page_type = create_page_type
      assert !page_type.new_record?, "#{page_type.errors.full_messages.to_sentence}"
    end
  end

  def test_shouldnt_require_key
    assert_difference "PageType.count" do
      page_type = create_page_type :key => ""
      assert !page_type.new_record?, "#{page_type.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_require_name
    assert_no_difference "PageType.count" do
      page_type = create_page_type :name => ""
      assert page_type.errors.on(:name)
    end
  end

  def test_shouldnt_require_key
    assert_difference "PageType.count" do
      page_type = create_page_type :key => ""
      assert !page_type.new_record?, "#{page_type.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_uniqueness_of_name
    page_type = create_page_type :name => "test"
    assert_no_difference "PageType.count" do
      page_type = create_page_type :name => "test"
      assert page_type.errors.on(:name)
    end
  end

  def test_should_require_uniqueness_of_key
    page_type = create_page_type :key => "test"
    assert_no_difference "PageType.count" do
      page_type = create_page_type :key => "test"
      assert page_type.errors.on(:key)
    end
  end

  private
  
  def create_page_type(options = {})
    default_options = {
      :name => 'default_name',
      :key => 'default_key',
    }
    PageType.create(default_options.merge(options))
  end
end
