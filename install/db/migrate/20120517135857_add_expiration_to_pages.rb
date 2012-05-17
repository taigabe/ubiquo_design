class AddExpirationToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :expiration, :text
  end

  def self.down
    remove_column :pages, :expiration
  end
end
