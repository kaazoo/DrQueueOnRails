class RendersessionsController < ApplicationController
  before_filter :authenticate_user!

  require 'money'
  require 'money/bank/google_currency'

  protect_from_forgery


  # GET /rendersessions/1
  # GET /rendersessions/1.xml
  def show
    @rendersession = Rendersession.find(params[:id])

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
      @rendersessions = Rendersession.all(:conditions => { :user => current_user.name }, :sort => [[ :name, :asc ]])

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
    if (current_user.admin != true) && (@rendersession.user != current_user.name)
      redirect_to :controller => 'main', :action => 'index' and return
    else
    
    # it's not allowed to edit paid rendersessions
    if @rendersession.paid_at != nil
      redirect_to :controller => 'main', :action => 'index' and return
    end

      # fetch all unconnected payments
      #all_payments = Payment.find(:all)
      #@payments = []
      #all_payments.each do |pm|
      #  puts pm.id
      #  if Rendersession.find_by_payment_id(pm.id) == nil
      #    @payments << pm
      #  end
      #end

      #@payments = Payment.find(:all)

      #@profiles = Profile.find(:all)

    end

  end


  # POST /rendersessions
  # POST /rendersessions.xml
  def create

    @rendersession = Rendersession.new(params[:rendersession])

    #puts params[:rendersession]
    #puts params[:rendersession_num_slaves]
    puts @rendersession.num_slaves
    puts @rendersession.run_time
    puts @rendersession.vm_type

    # only admins are allowed to use cloudcontrol
    if current_user.admin != true
      #redirect_to :controller => 'main', :action => 'index' and return
      @rendersession.user = current_user.name
      #@rendersession.payment_id = 0
      #@rendersession.costs = 0
    end

    puts @rendersession.user
    #puts @rendersession.payment_id
    puts @rendersession.costs

      # fetch all unconnected payments
      #all_payments = Payment.find(:all)
      #@payments = []
      #all_payments.each do |pm|
      #  puts pm.id
      #  if Rendersession.find_by_payment_id(pm.id) == nil
      #    @payments << pm
      #  end
      #end

      #@profiles = Profile.find(:all)

      respond_to do |format|
        if @rendersession.save
          if current_user.admin == true
            format.html { redirect_to(:controller => 'main', :action => 'cloudcontrol') }
          else
            format.html { redirect_to(:controller => 'rendersessions', :action => 'show', :id => @rendersession.id) }
          end
          #format.xml  { render :xml => @rendersession, :status => :created, :location => @rendersession }
        else
          format.html { render :action => "new" }
          #format.xml  { render :xml => @rendersession.errors, :status => :unprocessable_entity }
        end
      end
    #end
   end


  # PUT /rendersessions/1
  # PUT /rendersessions/1.xml
  def update

    @rendersession = Rendersession.find(params[:id])

    # only admins and owner are allowed
    if (current_user.admin != true) && (@rendersession.user != current_user.name)
      redirect_to :controller => 'main', :action => 'index' and return
    else

      respond_to do |format|
        if @rendersession.update_attributes(params[:rendersession])
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
    # only admins are allowed to use cloudcontrol
    if current_user.admin != true
      redirect_to :controller => 'main', :action => 'index' and return
    else
      @rendersession = Rendersession.find(params[:id])
      @rendersession.destroy

      respond_to do |format|
        format.html { redirect_to(:controller => 'rendersessions') }
        format.xml  { head :ok }
      end
    end

  end


  # costs calculation
  def calculate_costs

    puts num_nodes = params[:num_slaves].to_i
    puts usage_time = params[:run_time].to_i
    puts vm_type = params[:vm_type].to_s

    af_arr = ENV['CC_AWS_FEES'].split(",")
    aws_fee_t1micro = af_arr[0].to_f
    aws_fee_m1large = af_arr[1].to_f
    aws_fee_m1xlarge = af_arr[2].to_f
    aws_fee_c1xlarge = af_arr[3].to_f

    sf_arr = ENV['CC_SERVICE_FEES'].split(",")
    service_fee_t1micro = sf_arr[0].to_f
    service_fee_m1large = sf_arr[1].to_f
    service_fee_m1xlarge = sf_arr[2].to_f
    service_fee_c1xlarge = sf_arr[3].to_f

    sbf_arr = ENV['CC_SERVICE_BETA_FEES'].split(",")
    service_fee_beta_t1micro = sbf_arr[0].to_f
    service_fee_beta_m1large = sbf_arr[1].to_f
    service_fee_beta_m1xlarge = sbf_arr[2].to_f
    service_fee_beta_c1xlarge = sbf_arr[3].to_f

    discount_arr = ENV['CC_DISCOUNTS'].split(",")

    case vm_type
      when "t1.micro":
        real_costs = aws_fee_t1micro * usage_time * num_nodes
        beta_costs = (aws_fee_t1micro + service_fee_beta_t1micro) * usage_time * num_nodes
        customer_costs = (aws_fee_t1micro + service_fee_t1micro) * usage_time * num_nodes
        #puts real_costs.to_s+" "+beta_costs.to_s+" "+customer_costs.to_s
      when "m1.large":
        real_costs = aws_fee_m1large * usage_time * num_nodes
        beta_costs = (aws_fee_m1large + service_fee_beta_m1large) * usage_time * num_nodes
        customer_costs = (aws_fee_m1large + service_fee_m1large) * usage_time * num_nodes
        #puts real_costs.to_s+" "+beta_costs.to_s+" "+customer_costs.to_s
      when "m1.xlarge":
        real_costs = aws_fee_m1xlarge * usage_time * num_nodes
        beta_costs = (aws_fee_m1xlarge + service_fee_beta_m1xlarge) * usage_time * num_nodes
        customer_costs = (aws_fee_m1xlarge + service_fee_m1xlarge) * usage_time * num_nodes
        #puts real_costs.to_s+" "+beta_costs.to_s+" "+customer_costs.to_s
      when "c1.xlarge":
        real_costs = aws_fee_c1xlarge * usage_time * num_nodes
        beta_costs = (aws_fee_c1xlarge + service_fee_beta_c1xlarge) * usage_time * num_nodes
        customer_costs = (aws_fee_c1xlarge + service_fee_c1xlarge) * usage_time * num_nodes
        #puts real_costs.to_s+" "+beta_costs.to_s+" "+customer_costs.to_s
    end

    case usage_time
      when 1..9:
        discount = discount_arr[0].to_f
      when 10..19:
        discount = discount_arr[1].to_f
      when 20..29:
        discount = discount_arr[2].to_f
      when 30..39:
        discount = discount_arr[3].to_f
      when 40..49:
        discount = discount_arr[4].to_f
      when 50..59:
        discount = discount_arr[5].to_f
      when 60..99999:
        discount = discount_arr[6].to_f
      else
        discount = discount_arr[0].to_f
    end

    beta_costs_usd = sprintf('%.2f', beta_costs * discount)
    customer_costs_usd = sprintf('%.2f', customer_costs * discount)

    Money.default_bank = Money::Bank::GoogleCurrency.new
    n = beta_costs_usd.to_money(:USD)
    beta_costs_euro = n.exchange_to(:EUR)
    n = customer_costs_usd.to_money(:USD)
    customer_costs_euro = n.exchange_to(:EUR)

    beta_costs_euro_cents = (beta_costs_euro * 100).to_f.to_i

    #output_text = "Normal price: "+customer_costs_euro.to_s+" EUR / "+customer_costs_usd.to_s+" USD - Discount: "+((100 - discount*100).to_i).to_s+" %<br />"
    #output_text += "Beta users: "+beta_costs_euro.to_s+" EUR / "+beta_costs_usd.to_s+" USD"
    #render :text => output_text, :layout => false

    if current_user.beta_user == true
      render :text => beta_costs_euro, :layout => false
    else
      render :text => customer_costs_euro, :layout => false
    end

  end


end
