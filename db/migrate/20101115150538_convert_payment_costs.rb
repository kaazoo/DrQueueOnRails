class ConvertPaymentCosts < ActiveRecord::Migration
  def self.up
    remove_column :payments, :amount
    add_column :payments, :amount, :float
  end

  def self.down
    remove_column :payments, :amount
    add_column :payments, :amount, :decimal
  end
end
