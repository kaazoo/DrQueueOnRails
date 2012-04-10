class User
  include Mongoid::Document
  store_in "drqueue_users"

  field :name, :type => String
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  field :admin, :type => Boolean, :default => false
  field :beta_user, :type => Boolean, :default => false
  field :accepted_tos, :type => Boolean, :default => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  after_create :send_admin_mail


  # notify admin about new user registration
  def send_admin_mail
    AdminMailer.registration_notifier(self.email, self.name).deliver
  end

end
