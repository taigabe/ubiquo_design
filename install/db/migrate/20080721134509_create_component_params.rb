class CreateComponentParams < ActiveRecord::Migration
  def self.up
    create_table :component_params do |t|
      t.string :name
      t.boolean :is_required
      t.integer :widget_id

      t.timestamps
    end
    add_index :component_params, :widget_id
  end

  def self.down
    drop_table :component_params
  end
end
