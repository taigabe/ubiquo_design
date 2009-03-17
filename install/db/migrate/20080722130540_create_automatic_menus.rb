class CreateAutomaticMenus < ActiveRecord::Migration
  def self.up
    create_table :automatic_menus do |t|
      t.string :name
      t.string :generator

      t.timestamps
    end
  end

  def self.down
    drop_table :automatic_menus
  end
end
