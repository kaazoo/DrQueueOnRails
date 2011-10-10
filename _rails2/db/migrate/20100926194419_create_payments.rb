class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :profile_id
      t.date :paid_on
      t.decimal :amount

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
