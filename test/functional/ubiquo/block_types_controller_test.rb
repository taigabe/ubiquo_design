require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::BlockTypesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
    
  def test_shouldnt_update_without_permission
    login_as :eduard
    post :update, :page_id => pages(:one).id, :id => block_types(:one).id
    assert_response 403
  end
  
  def test_should_update_with_use_default_false
    run_update_with_use_default_false do |page, block_type|
      post :update, :page_id => page.id, :id => block_type.id
    end
  end

  def test_should_update_with_use_default_true
    run_update_with_use_default_true do |page, block_type|
      post :update, :page_id => page.id, :id => block_type.id, :use_default => 'true'
    end
  end

  def test_update_response_on_html_post_with_default_true
    page=nil
    block_type=nil
    run_update_with_use_default_true do |page, block_type|
      post :update, :page_id => page.id, :id => block_type.id, :use_default => 'true'
    end
    assert_redirected_to(ubiquo_page_design_path(page))
  end

  def test_update_response_on_xhr_post_with_default_true
    page=nil
    block_type=nil
    run_update_with_use_default_true do |page, block_type|
      xhr :post, :update, :page_id => page.id, :id => block_type.id, :use_default => 'true'
    end
    assert_select_rjs :remove, "block_#{block_type.id}"
    assert_select_rjs :insert_html, "use_default_#{block_type.id}" do 
      assert_select "#block_#{block_type.id}"
    end
  end



  private
  def run_update_with_use_default_false
    login_as
    assert_not_nil block_type = BlockType.find_all_by_can_use_default_block(true)[1]
    assert_not_nil page = block_type.page_templates.map(&:pages).flatten.select{|page| !page.url_name.blank?}.first
    assert_not_nil page.all_blocks_as_hash[block_type.key]
    assert_nil page.blocks.as_hash[block_type.key]
    yield page, block_type
    assert_not_nil page = assigns(:page)
    assert_not_nil block_type = assigns(:block_type)

    assert_not_nil page.all_blocks_as_hash[block_type.key]
    assert_not_nil page.blocks.as_hash[block_type.key]
  end
  def run_update_with_use_default_true
    run_update_with_use_default_false do |page, block_type|
      post :update, :page_id => page.id, :id => block_type.id
    end
    assert_not_nil page = assigns(:page)
    assert_not_nil block_type = assigns(:block_type)
    assert_not_nil page.all_blocks_as_hash[block_type.key]
    assert_not_nil page.blocks.as_hash[block_type.key]
    yield page, block_type
    assert_not_nil page = assigns(:page)
    assert_not_nil block_type = assigns(:block_type)
    assert_not_nil page.all_blocks_as_hash[block_type.key]
    assert_nil page.blocks.as_hash[block_type.key]
  end
end
