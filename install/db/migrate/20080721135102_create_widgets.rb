class CreateWidgets < ActiveRecord::Migration
  def self.up
    create_table :widgets do |t|
      t.string :name
      t.string :key
      t.boolean :is_configurable
      t.string :subclass_type

      t.timestamps
    end
    add_index :widgets, :key
  end

  def self.down
    drop_table :widgets
  end
end
