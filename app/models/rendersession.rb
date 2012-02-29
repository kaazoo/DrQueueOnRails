class Rendersession
  include Mongoid::Document
  store_in "cloudcontrol_rendersessions"

  field :user, :type => String
  field :num_slaves, :type => Integer
  field :run_time, :type => Integer
  field :vm_type, :type => String, :default => 't1.micro'
  field :costs, :type => Float
  field :active, :type => Boolean

  field :paypal_token, :type => String
  field :paypal_payer_id, :type => String
  field :paid_at, :type => DateTime

  field :time_passed, :type => Integer, :default => 0
  field :start_timestamp, :type => Integer, :default => 0
  field :stop_timestamp, :type => Integer, :default => 0
  field :overall_time_passed, :type => Integer, :default => 0
  
#  attr_accessible :user, :num_slaves, :run_time, :time_passed


end


