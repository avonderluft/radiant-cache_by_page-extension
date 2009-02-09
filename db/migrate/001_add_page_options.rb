class AddPageOptions < ActiveRecord::Migration
  def self.up   
    add_column :pages, :nocache, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :nocache
  end
end
