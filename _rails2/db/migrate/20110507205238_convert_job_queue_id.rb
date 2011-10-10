class ConvertJobQueueId < ActiveRecord::Migration
  def self.up
    remove_column :jobs, :queue_id
    add_column :jobs, :queue_id, :string
  end

  def self.down
    remove_column :jobs, :queue_id
    add_column :jobs, :queue_id, :integer
  end
end
