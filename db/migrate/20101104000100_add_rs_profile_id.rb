class AddRsProfileId < ActiveRecord::Migration
  def self.up
    add_column :rendersessions, :profile_id, :integer
  end

  def self.down
    remove_column :rendersessions, :profile_id
  end
end
