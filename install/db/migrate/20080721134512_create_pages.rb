class CreatePages < ActiveRecord::Migration
  def self.up
    uhook_create_pages_table do |t|
      t.string :name
      t.string :url_name
      t.integer :page_template_id
      t.integer :page_category_id
      t.integer :page_type_id
      t.boolean :is_public
      t.boolean :is_modified
      
      t.timestamps
    end
    
    add_index :pages, :url_name
    add_index :pages, :page_type_id
    add_index :pages, :page_category_id
    add_index :pages, :page_template_id
  end

  def self.down
    drop_table :pages
  end
end
