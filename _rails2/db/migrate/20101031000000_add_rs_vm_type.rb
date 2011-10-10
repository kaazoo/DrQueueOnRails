class AddRsVmType < ActiveRecord::Migration
  def self.up
    add_column :rendersessions, :vm_type, :string, :default => 't1.micro'
  end

  def self.down
    remove_column :rendersessions, :vm_type
  end
end
