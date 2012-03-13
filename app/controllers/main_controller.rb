class MainController < ApplicationController
  before_filter :authenticate_user!


  # start page
  def index

    # force user to accept disclaimer
    #if session[:profile].accepted == 0
    #  redirect_to :action => 'disclaimer' and return
    #end

    # check for greetings file in public directory
    greetings_file = File.join(Rails.root, '/public/greetings.html')
    if File.exist?(greetings_file)
      gf = File.open(greetings_file, "r")
      @greetings = gf.read
    else
      @greetings = ""
    end

  end


  # tutorials page
  def tutorials
  end


  # list of computers
  def computers

    cache_time = 60

    if params[:id] != nil
      # get info about special computer
      puts @computer_info = $pyDrQueueClient.identify_computer(params[:id].to_i, cache_time)
    else
      # update list of all computers
      @computer_list = []
      $pyDrQueueClient.ip_client.ids.rubify.each do |comp_id|
        puts info = $pyDrQueueClient.identify_computer(comp_id, cache_time)
        @computer_list << info
      end
    end

    # refresh timer
    #  link = url_for(:controller => 'main', :action => 'computers', :id => params[:id], :protocol => ENV['WEB_PROTO']+"://")
    #  if params[:refresh] != nil
    #    if params[:refresh] == ""
    #      @refresh_content = nil
    #      session[:last_refresh] = nil
    #    else
    #      @refresh_content = params[:refresh]+'; URL='+link
    #      session[:last_refresh] = params[:refresh]
    #    end
    #  elsif session[:last_refresh] != nil
    #    @refresh_content = session[:last_refresh]+'; URL='+link
    #  else
    #    @refresh_content = '300; URL='+link
    #  end

  end


  # cloudcontrol page
  def cloudcontrol
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      # fetch all running sessions
      @rendersessions = Rendersession.find(:all)

      # fetch all unconnected payments
      all_payments = Payment.find(:all)
      @payments = []
      all_payments.each do |pm|
        puts pm.id
        if Rendersession.find_by_payment_id(pm.id) == nil
          @payments << pm
        end
      end
    end
  end

end
