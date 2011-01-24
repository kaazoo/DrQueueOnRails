class ProfilesController < ApplicationController
  
  require 'rubygems'
  
  # for drqueue
  require 'drqueue'

  # for hash computation
  require 'digest/md5'

  # for disk usage output
  include ActionView::Helpers::NumberHelper

  # template
  layout "main_layout"

  
  def index
    list
    render :action => 'list'
  end


  def list
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main' and return
    else
      @profiles = Profile.paginate :page => params[:page]
      # @profile_pages, @profiles = paginate :profiles, :per_page => 10
      session[:return_path] = url_for(:controller => 'profiles', :action => 'list', :protocol => ENV['WEB_PROTO']+"://")
    end
    
  end


  def show
    # only id owner and admins are allowed to view profile
    if (session[:profile].id != params[:id].to_i) && (session[:profile].status != 'admin')
      redirect_to :controller => 'main' and return
    else
      @profile = Profile.find(params[:id])

      if ENV['CLOUDCONTROL'] == "true"
        user_hash = Digest::MD5.hexdigest(profile.ldap_account)
        userdir = ENV['DRQUEUE_TMP']+"/"+user_hash.to_s
      elsif ENV['USER_TMP_DIR'] == "id"
        userdir = ENV['DRQUEUE_TMP']+"/"+profile.id.to_s
      elsif ENV['USER_TMP_DIR'] == "ldap_account"
        userdir = ENV['DRQUEUE_TMP']+"/"+profile.ldap_account.to_s
      end

      # use user and quota settings from environment.rb
      status_arr = ENV['USER_STATUS'].split(",")
      quota_arr = ENV['USER_QUOTA'].split(",")
    
      # check if every array member has a partner
      if status_arr.length != quota_arr.length
        flash[:notice] = 'The user/quota/priorities settings seem to be wrong. Please contact the system administrator.'
        redirect_to :controller => 'main' and return
      end
    
      i = 0
      @quota = 0
      status_arr.each do |stat|
        if @profile.status == stat
          @quota = quota_arr[i].to_f
        end
        i += 1
      end

      # calculate quota usage (in GB)
      if File.directory?(userdir)
        # userdir size in KB
        du = `du -s #{userdir} | awk '{print $1}'`.to_f   
        @usage = (100 - ((@quota - (du / 1048576.0)) * 100 / @quota)).round
        @used = number_to_human_size(du * 1024)
        
        # no status flag in profile (for whatever reason)
        if @quota == 0
          @usage = 0
        end
        
        # user reached quota
        if @usage >= 100
          @reached = 1
        else
          @reached = 0
        end
          
      else
        @used = 0
        @usage = 0
      end
      
      # fetch render sessions
      @rendersessions = Rendersession.find_all_by_profile_id(@profile.id)

      # fetch payments
      @payments = Payment.find_all_by_profile_id(@profile.id)

      session[:return_path] = url_for(:controller => 'profiles', :action => 'show', :id => params[:id], :protocol => ENV['WEB_PROTO']+"://")
    end
    
  end


  def edit
    @profile = Profile.find(params[:id])

    status_arr = ENV['USER_STATUS'].split(",")
    @option_arr = []

    status_arr.each do |stat|
      @option_arr << [stat.capitalize, stat]
    end
  end


  def update
    @profile = Profile.find(params[:id])
    if @profile.update_attributes(params[:profile])
      flash[:notice] = 'Profile was successfully updated.'
      redirect_to :action => 'show', :id => @profile
    else
      render :action => 'edit'
    end
    
  end
  
  
  # delete user profile and all jobs belonging to it
  # note: as we use ldap, a profile will be recreated on the next login 
  def destroy
    # only admin are allowed
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main' and return
    end
    
    # search for all jobs of profile
    jobs = Job.find_all_by_profile_id(params[:id].to_i)
    
    jobs.each do |job|
      # seek for job info in master
      if job_m = Job.job_data_from_master(job.queue_id)
      
        # delete in master
        job_m.request_delete(Drqueue::CLIENT)
      
        # delete in db
        job.destroy
      end
      
      # delete userdir
      if ENV['USER_TMP_DIR'] == "id"
        userdir = ENV['DRQUEUE_TMP']+"/"+@profile.id.to_s
      elsif ENV['USER_TMP_DIR'] == "ldap_account"
        userdir = ENV['DRQUEUE_TMP']+"/"+@profile.ldap_account.to_s
      elsif ENV['CLOUDCONTROL'] == "true"
        user_hash = Digest::MD5.hexdigest(@profile.ldap_account)
        userdir = ENV['DRQUEUE_TMP']+"/"+user_hash.to_s
      end

      if File.exist? userdir
        puts `rm -rf #{userdir}`
      end
    end

    # delete profile
    Profile.find(params[:id]).destroy
    
    redirect_to :action => 'list'
  end
  
  
  
  
end
