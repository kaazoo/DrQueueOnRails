class JobsController < ApplicationController

  # template
  #layout "main_layout", :except => [:feed, :load_image]


  def index
    list
    render :action => 'list'
  end


  def list  
    # update list of all computers
    #Job.global_computer_list(1)

    #if (params[:id] == 'all') && (session[:profile].status == 'admin')
      # get all jobs from db
      @jobs = Job.all

      # get all jobs from master which are not in db
      #@jobs_only_master = Job.no_db_jobs()

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :id => 'all', :protocol => ENV['WEB_PROTO']+"://")
    #else
      # get only owners jobs from db
      #@jobs_db = Job.find_all_by_profile_id(session[:profile].id)

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :protocol => ENV['WEB_PROTO']+"://")
    #end

    # refresh timer
    #link = url_for(:controller => 'jobs', :action => 'list', :id => params[:id], :protocol => ENV['WEB_PROTO']+"://")
    #if params[:refresh] != nil
    #  if params[:refresh] == ""
    #    @refresh_content = nil
    #    session[:last_refresh] = nil
    #  else
    #   @refresh_content = params[:refresh]+'; URL='+link
    #   session[:last_refresh] = params[:refresh]
    #  end
    #elsif session[:last_refresh] != nil
    #  @refresh_content = session[:last_refresh]+'; URL='+link
    #else
    #  @refresh_content = '300; URL='+link
    #end
    
  end

  
end
