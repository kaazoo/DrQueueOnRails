class RendersessionsController < ApplicationController
  before_filter :authenticate_user!

  protect_from_forgery


  # GET /rendersessions/1
  # GET /rendersessions/1.xml
  def show
    @rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (@rendersession.user != current_user.id.to_s)
      redirect_to :controller => 'rendersessions', :action => 'index' and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rendersession }
    end
  end

  # GET /rendersessions
  # GET /rendersessions.xml
  def index

    if current_user.admin == true
      # get all jobs from db
      @rendersessions = Rendersession.all(:sort => [[ :name, :asc ]])

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :id => 'all', :protocol => ENV['WEB_PROTO']+"://")
    else
      # get only owners jobs from db
      @rendersessions = Rendersession.all(:conditions => { :user => current_user.id }, :sort => [[ :name, :asc ]])

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

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rendersessions }
    end

  end



  # GET /rendersessions/new
  # GET /rendersessions/new.xml
  def new
    @rendersession = Rendersession.new

    # fetch all unconnected payments
    #all_payments = Payment.find(:all)
    #@payments = []
    #all_payments.each do |pm|
    #  if Rendersession.find_by_payment_id(pm.id) == nil
    #    @payments << pm
    #  end
    #end

    @profiles = User.find(:all)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rendersession }
    end

  end


  # GET /rendersessions/1/edit
  def edit

    @rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (@rendersession.user != current_user.id.to_s)
      redirect_to :controller => 'rendersessions', :action => 'index' and return
    else
      # it's not allowed to edit paid rendersessions
      if @rendersession.paid_at != nil
        redirect_to :controller => 'rendersessions', :action => 'index' and return
      end
    end

  end


  # POST /rendersessions
  # POST /rendersessions.xml
  def create

    @rendersession = Rendersession.new(params[:rendersession])

    @rendersession.user = current_user.id

    # round and have at least 1
    @rendersession.num_slaves = params[:rendersession][:num_slaves].to_f.round
    if @rendersession.num_slaves < 1
      @rendersession.num_slaves = 1
    end
    @rendersession.run_time = params[:rendersession][:run_time].to_f.round
    if @rendersession.run_time < 1
      @rendersession.run_time = 1
    end

    @rendersession.vm_type = params[:rendersession][:vm_type].to_s

    # recalculate costs, so we don't trust form input
    puts @rendersession.costs = Rendersession.calculate_costs(current_user.beta_user, @rendersession.num_slaves, @rendersession.run_time, @rendersession.vm_type)

    # make rendersession active if none existing
    rendersessions = Rendersession.all(:conditions => { :user => current_user.id })
    if rendersessions.count == 0
      @rendersession.active = true
    else
      @rendersession.active = false
    end

    respond_to do |format|
      if @rendersession.save
        format.html { redirect_to(:controller => 'rendersessions', :action => 'show', :id => @rendersession.id) }
      else
        format.html { render :action => "new" }
      end
    end
   end


  # PUT /rendersessions/1
  # PUT /rendersessions/1.xml
  def update

    @rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (@rendersession.user != current_user.id.to_s)
      redirect_to :controller => 'rendersessions', :action => 'index' and return
    else
      # it's not allowed to update paid rendersessions
      if @rendersession.paid_at != nil
        redirect_to :controller => 'rendersessions', :action => 'index' and return
      end

      # round and have at least 1
      num_slaves = params[:rendersession][:num_slaves].to_f.round
      if num_slaves < 1
        num_slaves = 1
      end
      run_time = params[:rendersession][:run_time].to_f.round
      if run_time < 1
        run_time = 1
      end

      vm_type = params[:rendersession][:vm_type].to_s

      respond_to do |format|
        if @rendersession.update_attributes(params[:rendersession])

          # recalculate costs, so we don't trust form input
          puts @rendersession.costs = Rendersession.calculate_costs(current_user.beta_user, num_slaves, run_time, vm_type)

          @rendersession.num_slaves = num_slaves
          @rendersession.run_time = run_time

          @rendersession.save

          format.html { redirect_to(:action => 'show', :id => @rendersession) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @rendersession.errors, :status => :unprocessable_entity }
        end
      end
    end

  end


  # DELETE /rendersessions/1
  # DELETE /rendersessions/1.xml
  def destroy

    @rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (rendersession.user != current_user.id.to_s)
      redirect_to :controller => 'rendersessions', :action => 'index' and return
    else
      # it's not allowed to delete paid rendersessions
      if @rendersession.paid_at != nil
        redirect_to :controller => 'rendersessions', :action => 'index' and return
      end

      @rendersession.destroy

      respond_to do |format|
        format.html { redirect_to(:controller => 'rendersessions') }
        format.xml  { head :ok }
      end
    end

  end


  # set active rendersession
  def set_active

    rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (rendersession.user != current_user.id.to_s)
      redirect_to :controller => 'main', :action => 'index' and return
    else
      # mark all rendersesions of user as inactive
      rendersessions = Rendersession.all(:conditions => { :user => current_user.id })
      rendersessions.each do |rs|
        rs.active = false
        rs.save!
      end
      # mark current rendersession as active
      rendersession = Rendersession.find(params[:id])
      rendersession.active = true
      rendersession.save!

      respond_to do |format|
        format.html { redirect_to(:controller => 'rendersessions') }
        format.xml  { head :ok }
      end
    end

  end


  # set active rendersession for user
  def set_active_for_user

    puts rendersession = Rendersession.find(params[:id])
    puts user = User.find(params[:user])

    # only admins are allowed
    if current_user.admin != true
      redirect_to :controller => 'main', :action => 'index' and return
    else
      # mark all rendersesions of user as inactive
      rendersessions = Rendersession.all(:conditions => { :user => user.id })
      rendersessions.each do |rs|
        rs.active = false
        rs.save!
      end
      # mark current rendersession as active
      rendersession = Rendersession.find(params[:id])
      rendersession.active = true
      rendersession.save!

      respond_to do |format|
        format.html { redirect_to(:controller => 'rendersessions') }
        format.xml  { head :ok }
      end
    end

  end


  # give free rendersession to user
  def give_free_rendersession

    # only admins are allowed
    if current_user.admin != true
      redirect_to :controller => 'main', :action => 'index' and return
    end

    user_id = params[:id].to_s
    user = User.find(user_id)

    new_rs = Hash.new
    new_rs["user"] = user_id
    new_rs["num_slaves"] = ENV["FREE_RS_NUM_SLAVES"].to_i
    new_rs["run_time"] = ENV["FREE_RS_RUN_TIME"].to_i
    new_rs["vm_type"] = ENV["FREE_RS_VM_TYPE"].to_s
    new_rs["costs"] = 0
    new_rs["paypal_token"] = "NOT_NEEDED"
    new_rs["paypal_payer_id"] = "NOT_NEEDED"
    new_rs["paid_at"] = DateTime.now

    rendersession = Rendersession.new(new_rs)

    # make rendersession active if none existing
    rendersessions = Rendersession.all(:conditions => { :user => user_id })
    if rendersessions.count == 0
      rendersession.active = true
    else
      rendersession.active = false
    end

    rendersession.save

    # notify user about free rendersession
    UserMailer.free_rendersession_notifier(user.email, user.name).deliver

    redirect_to :controller => 'rendersessions', :action => 'index'
   end


  # costs calculation
  def calculate_costs_text

    # round and have at least 1
    num_slaves = params[:num_slaves].to_f.round
    if num_slaves < 1
      num_slaves = 1
    end
    run_time = params[:run_time].to_f.round
    if run_time < 1
      run_time = 1
    end

    vm_type = params[:vm_type].to_s

    costs_euro = Rendersession.calculate_costs(current_user.beta_user, num_slaves, run_time, vm_type)

    render :text => costs_euro, :layout => false
  end


end
