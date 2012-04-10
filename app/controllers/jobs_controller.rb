class JobsController < ApplicationController

  before_filter :authenticate_user!


  # for working with files
  require 'ftools'
  require 'fileutils'

  # for working with images
  require 'RMagick'

  # template
  #layout "main_layout", :except => [:feed, :load_image]


  def index
    list
    render :action => 'list'
  end


  def list  

    if current_user.admin == true
      # get all jobs from db
      @jobs = Job.all(:sort => [[ :name, :asc ]])

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :id => 'all', :protocol => ENV['WEB_PROTO']+"://")
    else
      # get only owners jobs from db
      @jobs = Job.all(:conditions => { :owner => current_user.id }, :sort => [[ :name, :asc ]])

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :protocol => ENV['WEB_PROTO']+"://")
    end

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
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    @owner_name = User.find(@job.owner).name

    # get tasks of job
    tasks_db = $pyDrQueueClient.query_task_list(@job._id.to_s)

    # add each Python task object to Ruby array
    @tasks = []
    while tasks_db.__len__ > 0
      @tasks << tasks_db.pop
    end

    # get average time per frame, time left and estimated finish time
    times = $pyDrQueueClient.job_estimated_finish_time(@job._id.to_s)
    @meantime = times[0].to_s
    @time_left = times[1].to_s
    @finish_time = times[2].to_s[0..18]


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

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    nr = params[:nr].to_i
    current_task = @job['startframe'].to_i + nr * @job['blocksize'].to_i
    end_of_block = @job['startframe'].to_i + nr * @job['blocksize'].to_i + @job['blocksize'].to_i - 1
    # use job directory as filename base
    logfile = @job['scenefile'].to_s.split(File::SEPARATOR)[-2] + "-" + current_task.to_s + "_" + end_of_block.to_s + ".log"
    @logfile = File.join(ENV['DRQUEUE_ROOT'], "logs", logfile)

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

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    @nr = params[:nr].to_i
    @startframe = @job['startframe'].to_i
    @nr_end = @nr + @job['blocksize'].to_i - 1
    @job_id = params[:id]

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

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    jobdir = File.dirname(@job['scenefile'].to_s)

    # get all files which are newer than the job scenefile
    scene_ctime = File.ctime(@job['scenefile'].to_s).to_i
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
    if imagefile == nil
      render :text => "<br /><br />Image file was not found.<br /><br />" and return false
    else
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

      img = Magick::Image::read(final_path).first
      send_file final_path, :filename => final_filename, :type => 'image/'+img.format.downcase, :disposition => 'inline'
    end
  end
  

  # continue a stopped job
  def continue

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    id_string = params[:id].to_s
    $pyDrQueueClient.job_continue(id_string)
    redirect_to :action => 'show', :id => id_string
  end


  # stop a job
  def stop

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    id_string = params[:id].to_s
    $pyDrQueueClient.job_stop(id_string)
    redirect_to :action => 'show', :id => id_string
  end


  # hard stop a job
  def hstop

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    id_string = params[:id].to_s
    $pyDrQueueClient.job_kill(id_string)
    redirect_to :action => 'show', :id => id_string
  end


  # delete a job
  def destroy

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    id_string = params[:id].to_s
    job = Job.find(id_string)
    jobdir = File.dirname(job['scenefile'].to_s)

    if ENV['CLOUDCONTROL'] == "true"
      userdir = File.join(ENV['DRQUEUE_ROOT'], "tmp", current_user.id.to_s)
    else
      userdir = File.join(ENV['DRQUEUE_ROOT'], "tmp", current_user.name)
    end

    if (job.created_with.to_s == "DrQueueOnRails") && (File.exist? jobdir) && (jobdir.include? userdir)
      FileUtils.cd(jobdir)
      FileUtils.cd("..")
      job_dirname = jobdir.split(File::SEPARATOR)[-1]
      puts "DEBUG: Deleted directory " + jobdir
      FileUtils.remove_dir(job_dirname, true)
    end

    $pyDrQueueClient.job_delete(id_string)

    redirect_to :controller => 'jobs' and return
  end


  # rerun a job
  def rerun

    # seek for job info in db
    @job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    id_string = params[:id].to_s
    job = Job.find(id_string)
    jobdir = File.dirname(job['scenefile'].to_s)

    # TODO: delete output archive
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

    $pyDrQueueClient.job_rerun(id_string)

    redirect_to :action => 'show', :id => id_string
  end


  # download results of a job
  def download

    # seek for job info in db
    job = Job.find(params[:id].to_s)

    # only owner and admin are allowed
    if (job != nil) && (job.owner != current_user.id.to_s) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    jobdir = File.dirname(job['scenefile'].to_s)

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
      send_file archive
    else
      # animation and cinema4d are always only packed
      if (job.rendertype == "animation") || (job.renderer == "cinema4d")
        # pack files in archive and send it to the user
        Job.pack_files(params[:id])
      else
        # combine parts and pack files
        Job.combine_parts(job)
        #if Job.combine_parts(job_db) == nil
        # redirect_to :action => 'new' and return
        #end
      end

      send_file archive
    end
  end


  def new

    #profile = Profile.find(session[:profile].id)

    @job = Job.new

    # default rendertype is animation
    @job.rendertype = "animation"

    # default file provider is upload
    @job.file_provider = "upload"

    # check if there is at least 500 MB available
    if Job.check_diskspace(500) == false
      flash[:notice] = 'There is less than 500 MB of free disk space avaiable. No new jobs at this time. Please contact the system administrator.' + df_free.to_s
      redirect_to :action => 'list' and return
    end

    # check disk usage of user
    #if Job.check_disk_usage(profile) == false
    #  flash[:notice] = 'Your disk quota is reached. No new jobs at this time. Please delete some old jobs or contact the system administrator.'
    #  redirect_to :action => 'list' and return
    #end

    # show only available renderers
    @renderers = []
    rend_array = ENV['AVAIL_RENDERERS'].split(",")
    rend_array.each do |ren|
      case ren
        when "blender"
          @renderers << ["Blender (internal renderer)", "blender"]
        when "blenderlux"
          @renderers << ["Blender (LuxRender renderer)", "blenderlux"]
        when "cinema4d"
          @renderers << ["Cinema 4D", "cinema4d"]
        when "luxrender"
          @renderers << ["LuxRender Standalone", "luxrender"]
        when "maya"
          @renderers << ["Maya (internal renderer)", "maya"]
        when "mayamr"
          @renderers << ["Maya (MentalRay renderer)", "mayamr"]
        when "mentalray"
          @renderers << ["MentalRay Standalone", "mentalray"]
        when "vray"
          @renderers << ["V-Ray Standalone", "vray"]
      end
    end

  end


  def create

    # check user input
    # TODO: use validate methods in the model
    if (params[:job][:name] == nil) || (params[:job][:name] == "")
      flash[:notice] = 'No name given.'
      redirect_to :action => 'new' and return
    end
    if ((params[:file] == nil) || (params[:file] == "")) && (params[:job][:file_provider] == "upload")
      flash[:notice] = 'No file uploaded.'
      redirect_to :action => 'new' and return
    end
    if ((params[:job][:scenefile] == nil) || (params[:job][:scenefile] == "")) && (params[:job][:file_provider] == "path")
      flash[:notice] = 'No scenefile specified.'
      redirect_to :action => 'new' and return
    end
    if (params[:job][:renderer] == nil) || (params[:job][:renderer] == "")
      flash[:notice] = 'No renderer given.'
      redirect_to :action => 'new' and return
    end
    if (params[:job][:rendertype] == nil) || (params[:job][:rendertype] == "")
      flash[:notice] = 'No rendertype given.'
      redirect_to :action => 'new' and return
    end
    if (params[:job][:startframe] == nil) || (params[:job][:startframe] == "") || (params[:job][:startframe].to_i < 1)
      flash[:notice] = 'No or wrong start frame given. Must be equal or greater 1.'
      redirect_to :action => 'new' and return
    end
    if (params[:job][:endframe] == nil) || (params[:job][:endframe] == "") || (params[:job][:endframe].to_i < 1)
      flash[:notice] = 'No or wrong end frame given. Must be equal or greater 1.'
      redirect_to :action => 'new' and return
    end
    if (params[:job][:blocksize] == nil) || (params[:job][:blocksize] == "") || (params[:job][:blocksize].to_i < 1)
      flash[:notice] = 'No or wrong blocksize given. Must be equal or greater 1.'
      redirect_to :action => 'new' and return
    end

    # sanitize and fill in user input
    job_name = params[:job][:name].strip
    job_startframe = params[:job][:startframe].strip.to_i
    job_endframe = params[:job][:endframe].strip.to_i
    job_blocksize = params[:job][:blocksize].strip.to_i
    job_renderer = params[:job][:renderer].strip
    if params[:job][:file_provider] == "path"
      job_scenefile = params[:job][:scenefile].strip
    end
    job_retries = 1000
    # set current user as owner
    job_owner = current_user.id.to_s
    job_created_with = "DrQueueOnRails"
    job_options = {}
    job_options['rendertype'] = params[:job][:rendertype]
    # set priority depending on user status
    # TODO
    #Job.set_priority(session[:profile].status)
    # TODO
    # email notification
    #if (session[:profile].ldap_account != "demo") && (ENV['DQOR_NOTIFY_EMAIL'] == "true")
    #  job_options['send_email'] = true
    #  job_options['email_recipients'] = session[:profile].email.to_s
    #end
    job_limits = {}

    # prepare some stuff when an archive was uploaded
    if (params[:file] != nil) && (params[:file] != "")

      # create user directory
      puts userdir = Job.create_userdir(current_user)

      # create job directory
      # we cannot use job_id here as we do not know it yet
      # we use all alphanumeric chars of the name plus current time in seconds as jobdir name
      puts jobdir = job_name.downcase.strip.gsub(/[^\w]/,'') + "_" + Time.now.to_i.to_s

      # process uploaded file
      status, message = Job.handle_upload(params[:file], userdir, jobdir)

      if status == false
        flash[:notice] = message
        redirect_to :action => 'new' and return
      end

      # Blender internal renderer
      if job_renderer == "blender"
        status, message, scenefile = Job.check_blender_file(userdir, jobdir)

        # debug return values
        puts status
        puts message
        puts scenefile

        if status == false
          flash[:notice] = message
          redirect_to :action => 'new' and return
        else
          puts job_scenefile = scenefile
        end

        # add job to specific pool
        if ENV['CLOUDCONTROL'] == "true"
          job_limits['pool_name']=current_user.id.to_s+"_blender"
        else
          job_limits['pool_name']="blender"
        end

      else
        # delete jobdir
        FileUtils.cd(userdir)
        FileUtils.remove_dir(jobdir, true)
        flash[:notice] = 'No correct renderer specified.'
        redirect_to :action => 'new' and return
      end

      # set permissions
      ### TODO: find a way to do this recursively in Ruby
      #`chmod o+rw -R #{userdir}`
      #`chmod g+rw -R #{userdir}`

    end

    # create job
    job_options = RubyPython::Conversion.rtopHash(job_options)
    job_limits = RubyPython::Conversion.rtopHash(job_limits)
    puts @job = $pyDrQueueJob.new(job_name, job_startframe, job_endframe, job_blocksize, job_renderer, job_scenefile, job_retries, job_owner, job_options, job_created_with, job_limits)

    # run job on renderfarm
    status =  $pyDrQueueClient.job_run(@job)
    if status == false
      flash[:notice] = 'There was an error while creating your job. Please contact the administrator.'
      redirect_to :action => 'new' and return
    else
      flash[:notice] = 'Job was successfully created.'
      # lookup job in order to get job id
      created_job = Job.where(:name => job_name.to_s).first
      redirect_to :action => 'show', :id => created_job['_id'].to_s
    end
  end


end
