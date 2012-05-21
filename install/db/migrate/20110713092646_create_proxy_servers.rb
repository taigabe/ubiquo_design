class CreateProxyServers < ActiveRecord::Migration
  def self.up
    create_table :proxy_servers do |t|
      t.string  :host
      t.integer :port

      t.timestamps
    end
  end

  def self.down
    drop_table :proxy_servers
  end
end
