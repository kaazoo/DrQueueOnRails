class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :check_tos, :except => [:display_tos, :accept_tos]


  # check if terms of service were accepted
  def accept_tos
    if params['accepted'].to_i == 1
      current_user.accepted_tos = true
      current_user.save!
    end
    redirect_to :controller => "main", :action => "index"
  end


  # display disclaimer to user
  def display_tos

  end


  # check if terms of service have been accepted by user
  def check_tos
    # allow Devise's controllers
    unless params[:controller].include? "devise"
      if (current_user != nil) && (current_user.accepted_tos != true)
        # check for tos file in public directory
        tos_file = File.join(Rails.root, '/public/tos.html')
        if File.exist?(tos_file)
          tf = File.open(tos_file, "r")
          @terms_of_service = tf.read
        else
          @terms_of_service = "Terms of service file is missing."
        end
        render :action => "display_tos"
      end
    end
  end


end
