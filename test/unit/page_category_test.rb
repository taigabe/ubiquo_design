require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageCategoryTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_page_category
    assert_difference "PageCategory.count" do
      page_category = create_page_category
      assert !page_category.new_record?, "#{page_category.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_require_valid_url_name
    assert_no_difference "PageCategory.count" do
      invalid_url_names = %w{foo/bar foo\\bar foo_bár}
      invalid_url_names.each do |url_name|
        page_category = create_page_category :url_name => url_name
        assert page_category.errors.on(:url_name)
      end
    end
  end
  
  def test_should_require_unique_url_name_and_name
    assert_difference "PageCategory.count", 1 do
      page_category_1 = create_page_category
      page_category_2 = create_page_category
      
      assert !page_category_1.new_record?, "#{page_category_1.errors.full_messages.to_sentence}"
      assert page_category_2.errors.on(:url_name)
      assert page_category_2.errors.on(:name)
    end
  end

  private
  
  def create_page_category(options = {})
    PageCategory.create({:name => "Custom page category", :url_name => "custom"}.merge(options))
  end
  
end
