class UserMailer < ActionMailer::Base
  default :from => ENV['DQOR_MAIL_FROM']

  def free_rendersession_notifier(email, name)
    @user_name = name
    @user_email = email
    @admin_address = ENV['DQOR_MAIL_ADMIN']

    case ENV["FREE_RS_VM_TYPE"]
      when "t1.micro"
        @vm_type_name = "Micro"
      when "m1.small"
        @vm_type_name = "Small"
      when "m1.medium"
        @vm_type_name = "Medium"
      when "m1.large"
        @vm_type_name = "Large"
      when "m1.xlarge"
        @vm_type_name = "Extra Large (RAM)"
      when "c1.xlarge"
        @vm_type_name = "Extra Large (CPU)"
      else
        @vm_type_name = "Unknown"
      end

    mail(:to => @user_email, :subject => "You received a free rendersession.")
  end

end
