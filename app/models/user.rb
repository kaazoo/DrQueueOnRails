class User
  include Mongoid::Document
  store_in "drqueue_users"

  field :name, :type => String
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  field :admin, :type => Boolean, :default => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :admin

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

end
