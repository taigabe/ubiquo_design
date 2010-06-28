class CreateComponents < ActiveRecord::Migration
  def self.up
    uhook_create_components_table do |t|
      t.text :options
      t.integer :widget_id
      t.integer :block_id
      t.integer :position
      t.string :type
      t.string :name

      t.timestamps
    end
    add_index :components, :widget_id
    add_index :components, :block_id
    add_index :components, :type
  end

  def self.down
    drop_table :components
  end
end
