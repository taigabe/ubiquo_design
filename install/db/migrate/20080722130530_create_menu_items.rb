class CreateMenuItems < ActiveRecord::Migration
  def self.up
    uhook_create_menu_items_table do |t|
      t.integer :parent_id
      t.string :caption
      t.string :url
      t.text :description
      t.boolean :is_linkable
      t.boolean :is_active
      t.integer :automatic_menu_id
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :menu_items
  end
end
