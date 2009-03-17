class CreateBlocks < ActiveRecord::Migration
  def self.up
    create_table :blocks do |t|
      t.integer :block_type_id
      t.integer :page_id
      
      t.timestamps
    end
      add_index :blocks, :block_type_id
      add_index :blocks, :page_id
  end

  def self.down
    drop_table :blocks
  end
end
