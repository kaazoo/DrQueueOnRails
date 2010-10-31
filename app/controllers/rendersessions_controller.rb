class RendersessionsController < ApplicationController

  # template
  layout "main_layout"


  # GET /rendersessions
  # GET /rendersessions.xml
  #def index
  #  @rendersessions = Rendersession.all
  #
  #  respond_to do |format|
  #    format.html # index.html.erb
  #    format.xml  { render :xml => @rendersessions }
  #  end
  #end

  # GET /rendersessions/1
  # GET /rendersessions/1.xml
  #def show
  #  @rendersession = Rendersession.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @rendersession }
  #  end
  #end


  # GET /rendersessions/new
  # GET /rendersessions/new.xml
  def new
    # only admins are allowed to use cloudcontrol
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.new
      
      # fetch all unconnected payments
      all_payments = Payment.find(:all)
      @payments = []
      all_payments.each do |pm|
        puts pm.id
        if Rendersession.find_by_payment_id(pm.id) == nil
          @payments << pm
        end
      end
    
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @rendersession }
      end
    end

  end


  # GET /rendersessions/1/edit
  def edit
    # only admins are allowed to use cloudcontrol
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.find(params[:id])
      
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


  # POST /rendersessions
  # POST /rendersessions.xml
  def create
    # only admins are allowed to use cloudcontrol
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.new(params[:rendersession])
      
      # fetch all unconnected payments
      all_payments = Payment.find(:all)
      @payments = []
      all_payments.each do |pm|
        puts pm.id
        if Rendersession.find_by_payment_id(pm.id) == nil
          @payments << pm
        end
      end
    
      respond_to do |format|
        if @rendersession.save
          format.html { redirect_to(:controller => 'main', :action => 'cloudcontrol') }
          format.xml  { render :xml => @rendersession, :status => :created, :location => @rendersession }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @rendersession.errors, :status => :unprocessable_entity }
        end
      end
    end 
   end


  # PUT /rendersessions/1
  # PUT /rendersessions/1.xml
  def update
    # only admins are allowed to use cloudcontrol
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.find(params[:id])

      respond_to do |format|
        if @rendersession.update_attributes(params[:rendersession])
          format.html { redirect_to(:controller => 'main', :action => 'cloudcontrol') }
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
    # only admins are allowed to use cloudcontrol
    if session[:profile].status != 'admin'
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.find(params[:id])
      @rendersession.destroy

      respond_to do |format|
        format.html { redirect_to(:controller => 'main', :action => 'cloudcontrol') }
        format.xml  { head :ok }
      end
    end

  end




end
