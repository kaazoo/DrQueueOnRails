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


  def show

    # seek for job info in db
    @job = Job.find_by__id(params[:id].to_s)

    # get tasks of job
    tasks_db = $pyDrQueueClient.query_task_list(@job._id.to_s)

    # add each Python task object to Ruby array
    @tasks = []
    while tasks_db.__len__ > 0
      @tasks << tasks_db.pop
    end

    # only owner and admin are allowed (only for drqueuonrails-jobs, not from drqman)
    #if (@job != nil) && (@job.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    # get list of all computers
    #@computer_list = Job.global_computer_list()
    # get all frames of job
    #@frame_list = @job_data.request_frame_list(Drqueue::CLIENT)

    # refresh timer
    #if( (@job_data.status == Drqueue::JOBSTATUS_FINISHED) || (@job_data.status == Drqueue::JOBSTATUS_STOPPED) )
    #  @refresh_content = nil
    #  params[:refresh] != nil
    #else
    #  # destination of refresh
    #  link = url_for(:controller => 'jobs', :action => 'show', :id => params[:id], :protocol => ENV['WEB_PROTO']+"://")
    #  # timer was newly set
    #  if params[:refresh] != nil
    #    if params[:refresh] == ""
    #@refresh_content = nil
    #session[:last_refresh] = nil
  #else
  #  @refresh_content = params[:refresh]+'; URL='+link
  #  session[:last_refresh] = params[:refresh]
  #end
  #    end
   #   # timer was set before
   #   if session[:last_refresh] != nil
   #     @refresh_content = session[:last_refresh]+'; URL='+link
   #   end
   #   #else
   #     # @refresh_content = '300; URL='+link
   #   #end
   # end

  end

  
end
