class CreatePageTemplateComponentTypes < ActiveRecord::Migration
  def self.up
    create_table :page_template_component_types do |t|
      t.integer :page_template_id
      t.integer :component_type_id

      t.timestamps
    end
    add_index :page_template_component_types, :page_template_id
    add_index :page_template_component_types, :component_type_id
  end

  def self.down
    drop_table :page_template_component_types
  end
end
