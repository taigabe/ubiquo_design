class CreatePageTypes < ActiveRecord::Migration
  def self.up
    create_table :page_types do |t|
      t.string :name
      t.string :key

      t.timestamps
    end
    add_index :page_types, :key
  end

  def self.down
    drop_table :page_types
  end
end
