class CreateBlockTypes < ActiveRecord::Migration
  def self.up
    create_table :block_types do |t|
      t.string :name
      t.string :key
      t.boolean :can_use_default_block

      t.timestamps
    end
      add_index :block_types, :key
  end

  def self.down
    drop_table :block_types
  end
end
