class Job
  include Mongoid::Document
  store_in "drqueue_jobs"

  field :name, :type => String
  field :startframe, :type => Integer
  field :endframe, :type => Integer
  field :blocksize, :type => Integer
  field :renderer, :type => String
  field :scenefile, :type => String
  field :retries, :type => Integer
  field :owner, :type => String
  field :created_with, :type => String
  field :rendertype, :type => String
  field :send_email, :type => Boolean
  field :email_recipients, :type => String
  field :file_provider, :type => String


  def self.check_diskspace(min_amount)
    # check if more than min_amount MB free space avaiable
    ### FIXME: ugly way to determine disk space
    ### after some investigation I figured out that no portable Ruby function
    ### for this seems to exist
    df_output = `df -m #{ File.join(ENV['DRQUEUE_ROOT'], "tmp") }`.split("\n")

    # switch to second line (when mountpoint path is too long)
    if (df_free = df_output[1].split[3]) == nil
      df_free = df_output[2].split[2]
    end

    if df_free.to_i < min_amount
      return false
    else
      return true
    end
  end


  def self.check_disk_usage(profile)

    # user hash
    user_hash = Digest::MD5.hexdigest(profile.ldap_account)

    # TODO: use File.join()
    # create user directory
    if ENV['CLOUDCONTROL'] == "true"
      userdir = ENV['DRQUEUE_TMP']+"/"+user_hash.to_s
    elsif ENV['USER_TMP_DIR'] == "id"
      userdir = ENV['DRQUEUE_TMP']+"/"+profile.id.to_s
    elsif ENV['USER_TMP_DIR'] == "ldap_account"
      userdir = ENV['DRQUEUE_TMP']+"/"+profile.ldap_account.to_s
    end

    if File.directory?(userdir)
      # calculate quota usage (in GB)

      # use user and quota settings from environment.rb
      status_arr = ENV['USER_STATUS'].split(",")
      quota_arr = ENV['USER_QUOTA'].split(",")

      # check if every array member has a partner
      if status_arr.length != quota_arr.length
        puts 'The user/quota/priorities settings seem to be wrong. Please contact the system administrator.'
        return false
      end

      i = 0
      quota = 0
      status_arr.each do |stat|
        if profile.status == stat
          quota = quota_arr[i].to_f
        end
        i += 1
      end

      # userdir size in KB
      du = `du -s #{userdir} | awk '{print $1}'`.to_f
      used = du / 1048576.0

      if used > quota
        return false
      else
        return true
      end
    end
  end


  # set priority depending on user status
  def self.set_priority(status)

    # use user and priorities settings from environment.rb
    status_arr = ENV['USER_STATUS'].split(",")
    prio_arr = ENV['USER_PRIO'].split(",")

    # check if every array member has a partner
    if status_arr.length != prio_arr.length
      return false, 'The user/quota/priorities settings seem to be wrong. Please contact the system administrator.'
    end

    i = 0
    priority = 10
    status_arr.each do |stat|
        if status == stat
          priority = prio_arr[i].to_i
        end
        i += 1
    end

    return priority
  end


  # create user directory
  def self.create_userdir(profile)

    # TODO: use File.join()
    if ENV['CLOUDCONTROL'] == "true"
      user_hash = Digest::MD5.hexdigest(profile.ldap_account)
      userdir = ENV['DRQUEUE_TMP'] + "/" + user_hash.to_s
    elsif ENV['USER_TMP_DIR'] == "id"
      userdir = ENV['DRQUEUE_TMP'] + "/" + profile.id.to_s
    elsif ENV['USER_TMP_DIR'] == "ldap_account"
      userdir = ENV['DRQUEUE_TMP'] + "/" + profile.ldap_account.to_s
    end

    if File.directory?(userdir)
      File.makedirs(userdir)
    end
  end


  # process uploaded file
  def self.handle_upload(upload, userdir, jobdir)

    # create jobdir inside userdir
    File.makedirs(File.join(userdir, jobdir))

    # get only the filename (not the whole path) and use only alphanumeric chars
    just_filename = File.basename(upload.original_filename).downcase.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '')

    # extract ending of file
    ending = just_filename[(just_filename.rindex('.')+1)..(just_filename.length)]

    # examine ending
    if (ending != 'tgz') && (ending != 'tbz2') && (ending != 'rar') && (ending != 'zip')
      # delete jobdir
      #system("rm -rf "+jobdir)
      FileUtils.cd(userdir)
      FileUtils.remove_dir(jobdir, true)
      return false, 'Archive file has to be in tgz, tbz2, rar or zip format.'
    else
      # save uploaded archive file to jobdir
      # copy is used when filesize > 10 KB (class ActionController::UploadedStringIO)
      if params[:file].class == ActionController::UploadedStringIO
        File.open(File.join(jobdir, just_filename),'wb') do |file|
          file.write upload.read
        end
      else
        FileUtils.mv(upload.local_path, File.join(jobdir, just_filename))
      end
    end

    # extract files from archive file
    FileUtils.cd(jobdir)
    if (ending == 'tgz')
      exit_status = system("tar -xvzf " + just_filename)
    elsif (ending == 'tbz2')
      exit_status = system("tar -xvjf " + just_filename)
    elsif (ending == 'rar')
      exit_status = system("unrar x " + just_filename)
    elsif (ending == 'zip')
      exit_status = system("unzip " + just_filename)
    end

    if (exit_status == false)
      # delete jobdir
      FileUtils.cd(userdir)
      FileUtils.remove_dir(jobdir, true)
      return false, 'There was a problem while extracting the archive file.'
    end

    return true
  end


  def check_blender_file(userdir, jobdir)

    # find scene file in jobdir
    scenefile = Job.find_scenefile("blend")

    # possible errors
    if scenefile == -1
      # delete jobdir
      FileUtils.cd(userdir)
      FileUtils.remove_dir(jobdir, true)
      return false, 'More than one scene file was found. Please only upload one per job.'
    elsif scenefile == -2
      # delete jobdir
      FileUtils.cd(userdir)
      FileUtils.remove_dir(jobdir, true)
      return false, 'No scene file was found. Please check your archive file.'
    end

    ### FIXME: do we really have to do this?
    ### how can we automate the script file generation?
    #@jobm.koj = 2
    #@jobm.koji.blender.scene = jobdir+"/"+scenefile
    #@jobm.koji.blender.viewcmd = "fcheck $PROJECT/images/$IMAGE.$FRAME.sgi"
    #@jobm.koji.general.scriptdir = jobdir

    # add job to specific pool
    if ENV['CLOUDCONTROL'] == "true"
      @jobm.limits.pool=user_hash+"_blender"
    else
      @jobm.limits.pool="blender"
    end

    # use internal multithreading/multiprocessing
    @jobm.limits.nmaxcpuscomputer = 1

    # create job script
    if params[:job][:sort] == "animation"
      # each computer renders one frame of an animation
      puts @jobm.cmd = @jobm.generate_jobscript("blender", jobdir+"/"+scenefile, jobdir)
    elsif params[:job][:sort] == "image"
      # each computer renders one part of an image
      puts @jobm.cmd = @jobm.generate_jobscript("blender_image", jobdir+"/"+scenefile, jobdir)

      # set number of parts
      @jobm.frame_start = 1

      if params[:res_height].include? "low"
        @jobm.frame_end = 4
      elsif params[:res_height].include? "medium"
        @jobm.frame_end = 8
      elsif params[:res_height].include? "high"
        @jobm.frame_end = 16
      else
        @jobm.frame_end = 4
      end
    else
      # delete jobdir
      #system("rm -rf "+jobdir)
      FileUtils.cd(userdir)
      FileUtils.remove_dir(jobdir, true)
      flash[:notice] = 'Wrong scene sort specified.'
      redirect_to :action => 'new' and return
    end

    if (@jobm.cmd == nil)
      flash[:notice] = 'The job script could not be generated.'
      redirect_to :action => 'new' and return
    end
  end




end


