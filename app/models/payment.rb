class Payment < ActiveRecord::Base

  has_many :rendersessions
  belongs_to :profile

end
