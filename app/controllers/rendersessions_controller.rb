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

    # recalculate costs, so we don't trust form input
    puts @rendersession.costs = Rendersession.calculate_costs(current_user.beta_user, params[:rendersession][:num_slaves].to_i, params[:rendersession][:run_time].to_i, params[:rendersession][:vm_type].to_s)

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

      respond_to do |format|
        if @rendersession.update_attributes(params[:rendersession])

          # recalculate costs, so we don't trust form input
          puts @rendersession.costs = Rendersession.calculate_costs(current_user.beta_user, params[:rendersession][:num_slaves].to_i, params[:rendersession][:run_time].to_i, params[:rendersession][:vm_type].to_s)
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


  # costs calculation
  def calculate_costs_text

    puts num_nodes = params[:num_slaves].to_i
    puts usage_time = params[:run_time].to_i
    puts vm_type = params[:vm_type].to_s

    costs_euro = Rendersession.calculate_costs(current_user.beta_user, num_nodes, usage_time, vm_type)

    render :text => costs_euro, :layout => false
  end


end
