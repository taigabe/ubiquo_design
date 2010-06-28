class CreatePageTemplateWidgets < ActiveRecord::Migration
  def self.up
    create_table :page_template_widgets do |t|
      t.integer :page_template_id
      t.integer :widget_id

      t.timestamps
    end
    add_index :page_template_widgets, :page_template_id
    add_index :page_template_widgets, :widget_id
  end

  def self.down
    drop_table :page_template_widgets
  end
end
