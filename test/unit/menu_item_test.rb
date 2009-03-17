require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class MenuItemTest < ActiveSupport::TestCase
  use_ubiquo_fixtures  
  def test_should_create_menu_item
    assert_difference 'MenuItem.count' do
      menu_item = create_menu_item
      assert !menu_item.new_record?, "#{menu_item.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_url_if_is_linkable
    assert_no_difference 'MenuItem.count' do
      menu_item = create_menu_item(:url => "", :is_linkable => true)
      assert menu_item.errors.on(:url)
    end
  end

  def test_should_require_caption
    assert_no_difference 'MenuItem.count' do
      menu_item = create_menu_item(:caption => nil)
      assert menu_item.errors.on(:caption)
    end
  end

  def test_should_require_parent_id
    assert_no_difference 'MenuItem.count' do
      menu_item = create_menu_item(:parent_id => nil)
      assert menu_item.errors.on(:parent_id)
    end
  end
  
  def test_caption_should_be_unique
    menu_item = create_menu_item(:caption => "a_new_caption")
    assert_no_difference 'MenuItem.count' do
      menu_item_with_same_new = create_menu_item(:caption => "a_new_caption")
      assert menu_item_with_same_new.errors.on(:caption)
    end
  end
  
  def test_should_get_root_menu_items_ordered_by_position
    MenuItem.delete_all
    root1 = create_menu_item(:caption => 'caption1', :position => 1)
    root2 = create_menu_item(:caption => 'caption2', :position => 2)
    root3 = create_menu_item(:caption => 'caption3', :position => 3)
    child11 = create_menu_item(:caption => 'caption11', :parent_id => root1.id, :position => 1)
    child31 = create_menu_item(:caption => 'caption31', :parent_id => root3.id, :position => 1)
    assert_equal MenuItem.roots, [root1, root2, root3]
  end

  def test_should_set_next_position_on_create_menu_item
    root1 = create_menu_item(:caption => 'caption1', :position => 1)
    root2 = create_menu_item(:caption => 'caption1')
    assert_equal root2.position, root1.position + 1
  end
  
  def test_should_return_childs
    root1 = create_menu_item(:caption => 'caption1')
    child11 = create_menu_item(:caption => 'caption11', :parent_id => root1.id)
    child12 = create_menu_item(:caption => 'caption12', :parent_id => root1.id)
    assert_equal root1.children, [child11, child12]          
  end

  def test_should_return_parent
    root1 = create_menu_item(:caption => 'caption1')
    child11 = create_menu_item(:caption => 'caption11', :parent_id => root1.id)
    child12 = create_menu_item(:caption => 'caption12', :parent_id => root1.id)
    assert_equal child11.parent, root1          
  end
              
  def test_root_menu_items_can_have_children_if_automatic_menu_not_selected              
    root1 = create_menu_item(:caption => 'caption1', :automatic_menu_id => nil)
    assert root1.can_have_children?
  end

  def test_root_menu_items_cannot_have_children_if_automatic_menu_is_set              
    root1 = create_menu_item(:caption => 'caption1', 
      :automatic_menu_id => automatic_menus(:one).id)
    assert !root1.can_have_children?
  end

  def test_non_root_menu_items_cannot_have_children              
    root1 = create_menu_item(:caption => 'caption1')
    child11 = create_menu_item(:caption => 'caption11', :parent_id => root1.id)
    assert !child11.can_have_children?
  end

  def test_active_roots
    active_roots = MenuItem.active_roots
    assert_equal [menu_items(:one)], active_roots
  end
                
  def test_active_children
    root1 = menu_items(:one)
    active_children = root1.active_children
    assert_equal [menu_items(:one_child1)], active_children
  end

  private
  
  def create_menu_item(options = {})
    default_options = { 
      :caption => "Caption", 
      :url => "http://www.gnuine.com", 
      :description => "Gnuine webpage",
      :is_linkable => true,
      :parent_id => 0,
      :position => 0,
      :automatic_menu_id => nil,
    }
    MenuItem.create(default_options.merge(options))
  end
end
