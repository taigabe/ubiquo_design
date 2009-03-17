class CreatePageCategories < ActiveRecord::Migration
  def self.up
    create_table :page_categories do |t|
      t.string :name
      t.string :url_name

      t.timestamps
    end
    add_index :page_categories, :url_name
  end

  def self.down
    drop_table :page_categories
  end
end
