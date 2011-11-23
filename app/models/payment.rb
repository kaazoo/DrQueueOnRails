class Payment
  include Mongoid::Document
  store_in "cloudcontrol_payments"
  
  has_many :rendersessions
  
  field :user, :type => String
  field :paid_on, :type => Date
  field :amount, :type => Float
  
  attr_accessible :user, :paid_on, :amount

end


