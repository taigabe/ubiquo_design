require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class PageTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
    
  # Page.publish is a transaction
  self.use_transactional_fixtures = false
  
  
  def test_should_create_page
    assert_difference "Page.count" do
      page = create_page
      assert !page.new_record?, "#{page.errors.full_messages.to_sentence}"
    end
  end

  def test_should_create_page_with_empty_url
    p=Page.find_all_by_url_name("")
    p.map(&:destroy)
    assert_difference "Page.count" do
      page = create_page :url_name => ""
      assert !page.new_record?, "#{page.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Page.count" do
      page = create_page :name => ""
      assert page.errors.on(:name)
    end
  end

  def test_should_require_page_template
    assert_no_difference "Page.count" do
      page = create_page :page_template_id => nil
      assert page.errors.on(:page_template)
    end
  end

  def test_should_require_page_category
    assert_no_difference "Page.count" do
      page = create_page :page_category_id => nil
      assert page.errors.on(:page_category)
    end
  end

  def test_should_require_valid_url_name
    assert_no_difference "Page.count" do
      ["no spaces", "Lower_Case_only", "no:wrong*symbols", nil].each do |url|
        page = create_page :url_name => url
        assert page.errors.on(:url_name), "Url name should be wrong: '#{url}'"
      end
    end
  end

  def test_shouldnt_require_unique_url_name_with_different_page_type_id
    assert_difference "Page.count", 2 do

      page1 = create_page :url_name => "unique_url", :page_type_id => page_types(:one).id
      page2 = create_page :url_name => "unique_url", :page_type_id => page_types(:two).id

      assert !page1.new_record?, "#{page1.errors.full_messages.to_sentence}"
      assert !page2.new_record?, "#{page2.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_unique_url_name_with_same_page_type_id
    assert_difference "Page.count", 1 do
      page1 = create_page :url_name => "unique_url", :page_type_id => page_types(:one).id
      page2 = create_page :url_name => "unique_url", :page_type_id => page_types(:one).id

      assert !page1.new_record?, "#{page1.errors.full_messages.to_sentence}"
      assert page2.errors.on(:url_name)
    end
  end

  def test_should_create_page_with_default_blocks
    assert_difference "Page.count" do
      page = create_page :page_template_id => page_templates(:one).id
      assert !page.new_record?, "#{page.errors.full_messages.to_sentence}"
      page_blocks = page.all_blocks
      assert_equal page_blocks.size, page.page_template.block_types.size
      desired_blocks = page.default_blocks
      assert_equal page_blocks.size, desired_blocks.size
      assert !desired_blocks.empty?, "You should test with block types with default block assigned. Check your fixtures."
      desired_blocks.each do |block|
        assert page_blocks.include?(block), "Page '#{page.name}' does not contain the expected block '#{block.id}'"
      end
    end
  end

  def test_should_create_page_with_some_default_blocks
    assert_difference "Page.count" do
      page = create_page :page_template_id => page_templates(:two).id
      assert !page.new_record?, "#{page.errors.full_messages.to_sentence}"
      page_blocks = page.all_blocks
      assert_equal page_blocks.size, page.page_template.block_types.size
      desired_blocks = page.default_blocks
      assert_operator page_blocks.size, :>, desired_blocks.size
      assert !desired_blocks.empty?, "You should test with block types with default block assigned. Check your fixtures."
      desired_blocks.each do |block|
        assert page_blocks.include?(block), "Page '#{page.name}' does not contain the expected block '#{block.id}'"
      end
    end
  end

  def test_should_get_components_for_block_type
    page = pages(:one)
    block = page.all_blocks_as_hash[block_types(:one).key]
    assert block.components.size > 0 #needs something to test.
    block.components.each do |component|
      assert component.block.block_type == block_types(:one)
    end
  end

  def test_default_blocks_method
    page = create_page :page_template_id => page_templates(:one).id
    assert_equal page.default_blocks, page.page_template.block_types.map(&:default_block).compact
  end

  def test_publish_pages
    page = create_page :page_template_id => page_templates(:one).id
    page.blocks << pages(:one).blocks
    assert_equal page.is_public?, false
    assert_equal page.is_published?, false
    assert_raises ActiveRecord::RecordNotFound do
      Page.find_public(page.page_category.url_name, page.url_name)
    end
    num_blocks = page.blocks.size
    num_components = page.blocks.map(&:components).flatten.size
    assert num_blocks > 0
    assert num_components > 0
    assert_difference "Page.count" do #New page
      assert_difference "Block.count", num_blocks do # cloned blocks
        assert_difference "Component.count",num_components do # cloned components
          assert page.publish
        end
      end
    end
    published = Page.find_public(page.page_category.url_name, page.url_name)
    assert_not_nil published
    assert_equal page.is_published?, true
  end

  def test_shouldnt_publish_wrong_pages
    page = create_page :page_template_id => page_templates(:one).id
    page.blocks << pages(:one).blocks
    assert_equal page.is_public?, false
    assert_equal page.is_published?, false
    assert_raises ActiveRecord::RecordNotFound do
      Page.find_public(page.page_category.url_name, page.url_name)
    end
    
    #creates an error on first component (Free)
    component = page.blocks.map(&:components).flatten.first
    assert_not_nil component
    assert_equal component.class, Free
    component.content = ""
    component.save_without_validation
    component.reload
    assert !component.valid?
    
    assert_no_difference "Page.count" do # no new page
      assert_no_difference "Block.count" do # no cloned blocks
        assert_no_difference "Component.count" do # no cloned components
          assert !page.publish
        end
      end
    end
    assert !page.is_published?
  end

  def test_should_destroy_both_pages
    page = pages(:one_design)
    assert_difference "Page.count", -2 do
      page.destroy
    end
  end

  def test_should_set_is_modified_on_save
    page = pages(:one_design)
    page.update_attributes(:is_modified => false)
    page.save
    assert page.is_modified?
  end

  private

  def create_page(options = {})
    Page.create({:name => "Custom page",
      :url_name => "custom_page",
      :page_template_id => page_templates(:one).id,
      :page_category_id => page_categories(:one).id,
      :page_type_id => page_types(:one).id,
      :is_public => false,
    }.merge(options))
  end
end
