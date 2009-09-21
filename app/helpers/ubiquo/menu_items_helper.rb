module Ubiquo::MenuItemsHelper

  def content_for_item(item)
    render :partial => 'list_item', :object => item
  end

  def build_item(item, parent_id)
    item_id = "#{parent_id}_#{item.id}"
    html = tag('li', {:id => item_id}, true)

    html += content_for_item(item)

    unless item.children.empty?
      item_as_parent_id = item_id + '_list'
      html += tag('ul', {:id => item_as_parent_id}, true)
      html += build_list(item.children, item_as_parent_id)
      html +="</ul>"
    end
    html += "</li>"
  end

  def build_list(items, parent_id)
    html = items.collect { |it| build_item(it, parent_id) }.join
    html += sortable_element(parent_id, {
      :url => update_positions_ubiquo_menu_items_url(:column => parent_id),
      :method => :put,
      :handle => 'handle'
    })
  end

end
