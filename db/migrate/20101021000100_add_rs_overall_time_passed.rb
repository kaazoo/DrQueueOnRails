class AddRsOverallTimePassed < ActiveRecord::Migration
  def self.up
    add_column :rendersessions, :overall_time_passed, :integer, :default => 0
  end

  def self.down
    remove_column :rendersessions, :overall_time_passed
  end
end
