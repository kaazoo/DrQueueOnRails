class PaymentsController < ApplicationController

  # template
  #layout "main_layout"


  # GET /payments
  # GET /payments.xml
  def index
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payments = Payment.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @payments }
      end
    end

  end


  # GET /payments/1
  # GET /payments/1.xml
  #def show
  #  @payment = Payment.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @payment }
  #  end
  #end


  # GET /payments/new
  # GET /payments/new.xml
  def new
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payment = Payment.new
      @profiles = User.find(:all)
  
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @payment }
      end
    end

  end


  # GET /payments/1/edit
  def edit
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payment = Payment.find(params[:id])
      @profiles = User.find(:all)
    end
  end


  # POST /payments
  # POST /payments.xml
  def create
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payment = Payment.new(params[:payment])
  
      respond_to do |format|
        if @payment.save
          #format.html { redirect_to(@payment, :notice => 'Payment was successfully created.') }
          format.html { redirect_to(:controller => 'main', :action => 'cloudcontrol', :notice => 'Payment was successfully created.') }
          format.xml  { render :xml => @payment, :status => :created, :location => @payment }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @payment.errors, :status => :unprocessable_entity }
        end
      end
    end

  end


  # PUT /payments/1
  # PUT /payments/1.xml
  def update
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payment = Payment.find(params[:id])
  
      respond_to do |format|
        if @payment.update_attributes(params[:payment])
          format.html { redirect_to(@payment, :notice => 'Payment was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @payment.errors, :status => :unprocessable_entity }
        end
      end
    end

  end


  # DELETE /payments/1
  # DELETE /payments/1.xml
  def destroy
    # only admins are allowed to use cloudcontrol
    if current_user.admin == false
      redirect_to :controller => 'main' and return
    else
      @payment = Payment.find(params[:id])
      @payment.destroy
  
      respond_to do |format|
        format.html { redirect_to(payments_url) }
        format.xml  { head :ok }
      end
    end

  end



end
