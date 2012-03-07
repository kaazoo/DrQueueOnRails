class PaymentsController < ApplicationController
  before_filter :authenticate_user!

  include ActiveMerchant::Billing


  def checkout
    # get rendersession from id
    rendersession = Rendersession.find(params[:rendersession])
    # check owner of rendersession
    if rendersession.user != current_user.id.to_s
      redirect_to :controller => 'main', :action => 'index' and return
    end
    # get costs of rendersession and use for gateway.setup_purchase()
    amount = (rendersession.costs * 100).to_i
    # initialize PayPal purchase
    setup_response = gateway.setup_purchase(
      amount,
      :ip                => request.remote_ip,
      :return_url        => url_for(:action => 'confirm', :amount => params[:amount].to_i, :only_path => false),
      :cancel_return_url => url_for(:controller => "rendersessions", :action => 'show', :id => rendersession, :only_path => false)
    )
    # store token in rendersession/paypal_token
    rendersession.paypal_token = setup_response.token
    # save rendersession
    rendersession.save
    # visit PayPal website
    redirect_to gateway.redirect_url_for(setup_response.token)
  end


  def confirm
    # check if token is given
    redirect_to :action => 'index' unless params[:token]
    # get rendersession from token
    @rendersession = Rendersession.first(:conditions => { :paypal_token => params[:token] })
    # check owner of rendersession
    if @rendersession.user != current_user.id.to_s
      redirect_to :controller => 'main', :action => 'index' and return
    end
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
    rendersession = Rendersession.first(:conditions => { :paypal_token => params[:token] })
    # check owner of rendersession
    if rendersession.user != current_user.id.to_s
      redirect_to :controller => 'main', :action => 'index' and return
    end
    # get costs of rendersession and use for gateway.purchase()
    amount = (rendersession.costs * 100).to_i
    # finalize PayPal purchase
    purchase = gateway.purchase(
      amount,
      :ip       => request.remote_ip,
      :payer_id => params[:payer_id],
      :token    => params[:token]
    )
    # store payer_id in rendersession/paypal_payer_id
    rendersession.paypal_payer_id = params[:payer_id]
    # store current date and time
    rendersession.paid_at = Time.now
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
      :signature => ENV['PP_API_SIGNATURE'],
      :default_currency => ENV['PP_CURRENCY']
    )
  end

end
