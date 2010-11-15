class ConvertCosts < ActiveRecord::Migration
  def self.up
    remove_column :rendersessions, :costs
    add_column :rendersessions, :costs, :float
  end

  def self.down
    remove_column :rendersessions, :costs
    add_column :rendersessions, :costs, :decimal
  end
end
