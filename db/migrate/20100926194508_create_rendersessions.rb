class CreateRendersessions < ActiveRecord::Migration
  def self.up
    create_table :rendersessions do |t|
      t.integer :num_slaves
      t.integer :run_time
      t.integer :payment_id
      t.integer :time_passed, :default => 0
      t.decimal :costs
      t.integer :start_timestamp, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :rendersessions
  end
end
