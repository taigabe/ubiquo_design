class CreatePageTemplates < ActiveRecord::Migration
  def self.up
    create_table :page_templates do |t|
      t.string :name
      t.string :key
      t.string :layout
      t.string :thumbnail_file_name
      
      t.timestamps
    end
      add_index :page_templates, :key
  end

  def self.down
    drop_table :page_templates
  end
end
