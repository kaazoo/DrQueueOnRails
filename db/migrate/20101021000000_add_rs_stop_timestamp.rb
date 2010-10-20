class AddRsStopTimestamp < ActiveRecord::Migration
  def self.up
    add_column :rendersessions, :stop_timestamp, :integer, :default => 0
  end

  def self.down
    remove_column :rendersessions, :stop_timestamp
  end
end
