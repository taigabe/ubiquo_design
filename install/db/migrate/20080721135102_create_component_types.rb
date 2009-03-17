class CreateComponentTypes < ActiveRecord::Migration
  def self.up
    create_table :component_types do |t|
      t.string :name
      t.string :key
      t.boolean :is_configurable
      t.string :subclass_type

      t.timestamps
    end
    add_index :component_types, :key
  end

  def self.down
    drop_table :component_types
  end
end
