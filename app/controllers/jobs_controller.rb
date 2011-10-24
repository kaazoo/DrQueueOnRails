class JobsController < ApplicationController

  # for hash computation
  require 'digest/md5'

  # for generating job scripts
  #require_dependency 'jobscript_generators'

  # for working with files
  require 'ftools'
  require 'fileutils'

  # for text sanitizing
  #include ActionView::Helpers::TextHelper

  # for working with images
  require 'RMagick'

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


  def view_log

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    @job = Job.find_by__id(params[:id].to_s)
    nr = params[:nr].to_i
    current_task = @job['startframe'].to_i + nr
    end_of_block = @job['startframe'].to_i + @job['blocksize'].to_i - 1 + nr
    logfile = @job['name'].to_s + "-" + current_task.to_s + "_" + end_of_block.to_s + ".log"
    @logfile = File.join(ENV['DRQUEUE_LOGS'], logfile)

    # refresh timer
    #link = url_for(:controller => 'jobs', :action => 'view_log', :id => params[:id], :nr => params[:nr], :protocol => ENV['WEB_PROTO']+"://")
    #if params[:refresh] != nil
    #  if params[:refresh] == ""
    #    @refresh_content = nil
    #    session[:last_refresh] = nil
    #  else
    #    @refresh_content = params[:refresh]+'; URL='+link
    #    session[:last_refresh] = params[:refresh]
    #  end
    #elsif session[:last_refresh] != nil
    #  @refresh_content = session[:last_refresh]+'; URL='+link
    #else
    #  @refresh_content = '300; URL='+link
    #end

  end


  def view_image

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    @nr = params[:nr].to_i
    @job_id = params[:id]
    @job = Job.find_by__id(params[:id].to_s)

    if @nr >= @job['endframe'].to_i
      redirect_to :action => 'list' and return
    end

    # refresh timer
    #link = url_for(:controller => 'jobs', :action => 'view_image', :id => params[:id], :nr => params[:nr], :protocol => ENV['WEB_PROTO']+"://")
    #if params[:refresh] != nil
    #  if params[:refresh] == ""
    #    @refresh_content = nil
    #    session[:last_refresh] = nil
    #  else
    #    @refresh_content = params[:refresh]+'; URL='+link
    #    session[:last_refresh] = params[:refresh]
    #  end
    #elsif session[:last_refresh] != nil
    #  @refresh_content = session[:last_refresh]+'; URL='+link
    #else
    #  @refresh_content = '300; URL='+link
    #end

  end


  def load_image

    job = Job.find_by__id(params[:id].to_s)
    jobdir = File.dirname(job['scenefile'].to_s)

    # get all files which are newer than the job scenefile
    scene_ctime = File.ctime(job['scenefile'].to_s).to_i
    found_files = []
    dir = Dir.open(jobdir)
    dir.each do |entry|
      entrypath = File.join(jobdir, entry)
      if (File.file? entrypath) && (File.ctime(entrypath).to_i > scene_ctime) && !(entry.start_with? '.') && !(entry.end_with? '.zip') && !(entry.end_with? '_preview.png')
        found_files << entry
      end
    end
    dir.close

    found_files.sort!
    imagefile = found_files[params[:nr].to_i]
    imagepath = File.join(jobdir, imagefile)

    # determine image type
    img = Magick::Image::read(imagepath).first
    # convert: BMP, Iris, TGA, TGA RAW, Cineon, DPX, EXR, Radiance HDR, TIF
    # don't convert: PNG, JPG
    case img.format
      when 'PNG', 'JPG', 'JPEG', 'JPX', 'JNG'
        # don't convert
        final_path = imagepath
        final_filename = imagefile
      when 'BMP', 'BMP2', 'BMP3', 'ICB', 'TGA', 'VDA', 'VST', 'CIN', 'DPX', 'EXR', 'PTIF', 'TIFF', 'TIFF64'
        # convert if not yet done
        if (File.file? imagepath + "_preview.png") == false
          # resize if too big
          if img.columns > 1000
            preview_img = img.resize_to_fit(1000)
          else
            preview_img = img
          end
          preview_img.format = "PNG"
          preview_img.write(imagepath + "_preview.png")
        end
        puts final_path = imagepath + "_preview.png"
        final_filename = File.basename(final_path)
    end

    if imagefile == nil
      render :text => "<br /><br />Image file was not found.<br /><br />" and return false
    else
      img = Magick::Image::read(final_path).first
      send_file final_path, :filename => final_filename, :type => 'image/'+img.format.downcase, :disposition => 'inline'
    end
  end
  

  # continue a stopped job
  def continue

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    $pyDrQueueClient.job_continue(params[:id].to_s)
    redirect_to :action => 'show', :id => params[:id]
  end


  # stop a job
  def stop

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    $pyDrQueueClient.job_stop(params[:id].to_s)
    redirect_to :action => 'show', :id => params[:id]
  end


  # hard stop a job
  def hstop

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    $pyDrQueueClient.job_kill(params[:id].to_s)
    redirect_to :action => 'show', :id => params[:id]
  end


  # delete a job
  def destroy

    job = Job.find_by__id(params[:id].to_s)
    jobdir = File.dirname(job['scenefile'].to_s)

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    if ENV['USER_TMP_PREFIX'] == "id"
      userdir = session[:profile].id.to_s
    elsif ENV['USER_TMP_PREFIX'] == "ldap_account"
      userdir = session[:profile].ldap_account.to_s
    elsif ENV['USER_TMP_PREFIX'] == "hash"
      userdir = Digest::MD5.hexdigest(session[:profile].ldap_account)
    else
      userdir = nil
    end

    puts userdir
    if (userdir != nil) && (File.exist? jobdir) && (jobdir.include? userdir)
      FileUtils.cd(jobdir)
      FileUtils.cd("..")
      puts job_dirname = jobdir.split(File::SEPARATOR)[-2]
      FileUtils.remove_dir(job_dirname, true)
    end

    $pyDrQueueClient.job_delete(params[:id].to_s)

    redirect_to session[:return_path] and return
  end


  # rerun a job
  def rerun

    job = Job.find_by__id(params[:id].to_s)
    jobdir = File.dirname(job['scenefile'].to_s)

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    # delete output archive
    #if `find . -maxdepth 1 -type f -name *.zip`.length > 0
    #  archive = renderpath + "/rendered_files_#{id_string}.zip"
    #elsif `find . -maxdepth 1 -type f -name *.tgz`.length > 0
    #  archive = renderpath + "/rendered_files_#{id_string}.tgz"
    #elsif `find . -maxdepth 1 -type f -name *.tbz2`.length > 0
    #  archive = renderpath + "/rendered_files_#{id_string}.tbz2"
    #elsif `find . -maxdepth 1 -type f -name *.rar`.length > 0
    #  archive = renderpath + "/rendered_files_#{id_string}.rar"
    #else
    #  archive = renderpath + "/rendered_files_#{id_string}.zip"
    #end

    puts archive = File.join(jobdir, 'rendered_files_' + id_string + '.tbz2')
    if File.exist? archive
      File.unlink(archive)
    end

    $pyDrQueueClient.job_rerun(params[:id].to_s)

    redirect_to :action => 'show', :id => params[:id]
  end


  # download results of a job
  def download

    job = Job.find_by__id(params[:id].to_s)
    jobdir = File.dirname(job['scenefile'].to_s)

    # only owner and admin are allowed
    #if (job_db.profile_id != session[:profile].id) && (session[:profile].status != 'admin')
    #  redirect_to :action => 'list' and return
    #end

    # path to renderings
    FileUtils.cd(jobdir)
    if `find . -maxdepth 1 -type f -name *.zip`.length > 0
      archive = File.join(jobdir, "rendered_files_#{params[:id].to_s}.zip")
    elsif `find . -maxdepth 1 -type f -name *.tgz`.length > 0
      archive = File.join(jobdir, "rendered_files_#{params[:id].to_s}.tgz")
    elsif `find . -maxdepth 1 -type f -name *.tbz2`.length > 0
      archive = File.join(jobdir, "rendered_files_#{params[:id].to_s}.tbz2")
    elsif `find . -maxdepth 1 -type f -name *.rar`.length > 0
      archive = File.join(jobdir, "rendered_files_#{params[:id].to_s}.rar")
    else
      archive = File.join(jobdir, "rendered_files_#{params[:id].to_s}.zip")
    end

    if File.exist? archive
      # find out which web server we are using
      if request.env["SERVER_SOFTWARE"].index("Apache") == nil
        # too slow for big files, only used without apache
        send_file archive
      else
        # use mod_xsendfile which is much faster
        x_send_file archive
      end
    else
      # animation and cinema4d are always only packed
      if (job_db.sort == "animation") || (job_db.renderer == "cinema4d")
        # pack files in archive and send it to the user
        Job.pack_files(params[:id].to_i)
      else
        # combine parts and pack files
        Job.combine_parts(job_db)
        #if Job.combine_parts(job_db) == nil
        # redirect_to :action => 'new' and return
        #end
      end

      # find out which web server we are using
      if request.env["SERVER_SOFTWARE"].index("Apache") == nil
        # too slow for big files, only used without apache
        send_file archive
      else
        # use mod_xsendfile which is much faster
        x_send_file archive
      end
    end
  end



end
