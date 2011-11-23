class Rendersession
  include Mongoid::Document
  store_in "cloudcontrol_rendersessions"

  belongs_to :payment
  
  field :user, :type => String
  field :num_slaves, :type => Integer
  field :run_time, :type => Integer
  field :costs, :type => Float
#  field :payment_id, :type => Integer
  field :time_passed, :type => Integer, :default => 0
  field :start_timestamp, :type => Integer, :default => 0
  field :stop_timestamp, :type => Integer, :default => 0
  field :overall_time_passed, :type => Integer, :default => 0
  field :vm_type, :type => String, :default => 't1.micro'
  
#  attr_accessible :user, :num_slaves, :run_time, :time_passed

end


