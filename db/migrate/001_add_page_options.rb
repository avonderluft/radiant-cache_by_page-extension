class AddPageOptions < ActiveRecord::Migration
  def self.up   
    add_column :pages, :cache_expire_minutes, :integer, :allow_nil => false, :default => 0
    add_column :pages, :cache_expire_time, :time, :default => nil  
  end

  def self.down
    remove_column :pages, :cache_expire_minutes
    remove_column :pages, :cache_expire_time
  end
end
