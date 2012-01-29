class PaymentsController < ApplicationController

  # template
  #layout "main_layout"

  include ActiveMerchant::Billing

  # GET /payments
  # GET /payments.xml
  def index
  
    if current_user.admin == true
      # get all payments from db
      @payments = Payment.all(:sort => [[ :name, :asc ]])

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :id => 'all', :protocol => ENV['WEB_PROTO']+"://")
    else
      # get only owners payments from db
      @payments = Payment.all(:conditions => { :user => current_user.name }, :sort => [[ :name, :asc ]])

      # set return path to list action
      #session[:return_path] = url_for(:controller => 'jobs', :action => 'list', :protocol => ENV['WEB_PROTO']+"://")
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payments }
    end

  end


  # GET /payments/1
  # GET /payments/1.xml
  def show

    # seek for payment info in db
    @payment = Payment.find(params[:id].to_s)

    # only owner and admin are allowed
    if (@job != nil) && (@job.owner != current_user.name) && (current_user.admin != true)
      redirect_to :controller => 'jobs' and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @payment }
    end
  end


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


  def checkout
    # get rendersession from id
    rendersession = Rendersession.find(params[:rendersession])
    # get costs of rendersession and use for gateway.setup_purchase()
    puts amount = (rendersession.costs * 100).to_i
    # initialize PayPal purchase
    setup_response = gateway.setup_purchase(
      amount,
      :ip                => request.remote_ip,
      :return_url        => url_for(:action => 'confirm', :amount => params[:amount].to_i, :only_path => false),
      :cancel_return_url => url_for(:action => 'index', :only_path => false)
    )
    # store token in rendersession/paypal_token
    puts rendersession.paypal_token = setup_response.token
    # save rendersession
    rendersession.save
    # visit PayPal website
    redirect_to gateway.redirect_url_for(setup_response.token)
  end


  def confirm
    redirect_to :action => 'index' unless params[:token]

    details_response = gateway.details_for(params[:token])

    if !details_response.success?
      @message = details_response.message
      render :action => 'error'
      return
    end

    @address = details_response.address
  end


  def complete
    # get rendersession from token
    puts rendersession = Rendersession.first(:conditions => { :paypal_token => params[:token] })
    # get costs of rendersession and use for gateway.purchase()
    puts amount = (rendersession.costs * 100).to_i
    # finalize PayPal purchase
    purchase = gateway.purchase(
      amount,
      :ip       => request.remote_ip,
      :payer_id => params[:payer_id],
      :token    => params[:token]
    )
    # store payer_id in rendersession/paypal_payer_id
    puts rendersession.paypal_payer_id = params[:payer_id]
    # save rendersession
    rendersession.save
    # show payment status
    if !purchase.success?
      @message = purchase.message
      render :action => 'error'
      return
    end
  end


  private
  def gateway
    @gateway ||= PaypalExpressGateway.new(
      :login => ENV['PP_API_LOGIN'],
      :password => ENV['PP_API_PASSWORD'],
      :signature => ENV['PP_API_SIGNATURE']
    )
  end

end
