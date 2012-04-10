class AdminMailer < ActionMailer::Base
  default :from => ENV['DQOR_MAIL_FROM']

  def registration_notifier(email, name)
    @user_name = name
    @user_email = email
    @admin_address = ENV['DQOR_MAIL_ADMIN']
    mail(:to => @admin_address, :subject => "User " + @user_name + " signed up")
  end

end
