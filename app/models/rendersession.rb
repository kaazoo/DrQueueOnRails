class Rendersession
  include Mongoid::Document
  store_in "cloudcontrol_rendersessions"

  field :user, :type => String
  field :num_slaves, :type => Integer
  field :run_time, :type => Integer
  field :vm_type, :type => String, :default => 't1.micro'
  field :costs, :type => Float
  field :active, :type => Boolean

  field :paypal_token, :type => String
  field :paypal_payer_id, :type => String
  field :paid_at, :type => DateTime

  field :time_passed, :type => Integer, :default => 0
  field :start_timestamp, :type => Integer, :default => 0
  field :stop_timestamp, :type => Integer, :default => 0
  field :overall_time_passed, :type => Integer, :default => 0
  
#  attr_accessible :user, :num_slaves, :run_time, :time_passed


  require 'money'
  require 'money/bank/google_currency'


  # costs calculation
  def self.calculate_costs(beta_user, num_nodes, usage_time, vm_type)

    puts num_nodes
    puts usage_time
    puts vm_type

    # value added tax (VAT) percentage by Amazon
    aws_vat_percentage = ENV['CC_AWS_VAT_PERCENTAGE'].to_f

    # fees by AWS for t1.micro, m1.small, m1.medium, m1.large, m1.xlarge, c1.xlarge in USD including VAT
    af_arr = ENV['CC_AWS_FEES'].split(",")
    aws_fee_t1micro = af_arr[0].to_f * aws_vat_percentage
    aws_fee_m1small = af_arr[1].to_f * aws_vat_percentage
    aws_fee_m1medium = af_arr[2].to_f * aws_vat_percentage
    aws_fee_m1large = af_arr[3].to_f * aws_vat_percentage
    aws_fee_m1xlarge = af_arr[4].to_f * aws_vat_percentage
    aws_fee_c1xlarge = af_arr[5].to_f * aws_vat_percentage

    # fees by PayPal in Euro
    paypal_percentage = ENV['PP_PERCENTAGE'].to_f
    paypal_transaction_fee = ENV['PP_TRANSACTION_FEE'].to_f

    # service fees for customers in USD
    sf_arr = ENV['CC_SERVICE_FEES'].split(",")
    service_fee_t1micro = sf_arr[0].to_f
    service_fee_m1small = sf_arr[1].to_f
    service_fee_m1medium = sf_arr[2].to_f
    service_fee_m1large = sf_arr[3].to_f
    service_fee_m1xlarge = sf_arr[4].to_f
    service_fee_c1xlarge = sf_arr[5].to_f

    # service fees for beta users in USD
    sbf_arr = ENV['CC_SERVICE_BETA_FEES'].split(",")
    service_fee_beta_t1micro = sbf_arr[0].to_f
    service_fee_beta_m1small = sbf_arr[1].to_f
    service_fee_beta_m1medium = sbf_arr[2].to_f
    service_fee_beta_m1large = sbf_arr[3].to_f
    service_fee_beta_m1xlarge = sbf_arr[4].to_f
    service_fee_beta_c1xlarge = sbf_arr[5].to_f

    # discounts
    discount_arr = ENV['CC_DISCOUNTS'].split(",")

    # costs are first calculated in USD because AWS fees are in USD
    case vm_type
      when "t1.micro":
        real_costs = aws_fee_t1micro * usage_time * num_nodes
        beta_costs = (aws_fee_t1micro + service_fee_beta_t1micro) * usage_time * num_nodes
        customer_costs = (aws_fee_t1micro + service_fee_t1micro) * usage_time * num_nodes
      when "m1.small":
        real_costs = aws_fee_m1small * usage_time * num_nodes
        beta_costs = (aws_fee_m1small + service_fee_beta_m1small) * usage_time * num_nodes
        customer_costs = (aws_fee_m1small + service_fee_m1small) * usage_time * num_nodes
      when "m1.medium":
        real_costs = aws_fee_m1medium * usage_time * num_nodes
        beta_costs = (aws_fee_m1medium + service_fee_beta_m1medium) * usage_time * num_nodes
        customer_costs = (aws_fee_m1medium + service_fee_m1medium) * usage_time * num_nodes
      when "m1.large":
        real_costs = aws_fee_m1large * usage_time * num_nodes
        beta_costs = (aws_fee_m1large + service_fee_beta_m1large) * usage_time * num_nodes
        customer_costs = (aws_fee_m1large + service_fee_m1large) * usage_time * num_nodes
      when "m1.xlarge":
        real_costs = aws_fee_m1xlarge * usage_time * num_nodes
        beta_costs = (aws_fee_m1xlarge + service_fee_beta_m1xlarge) * usage_time * num_nodes
        customer_costs = (aws_fee_m1xlarge + service_fee_m1xlarge) * usage_time * num_nodes
      when "c1.xlarge":
        real_costs = aws_fee_c1xlarge * usage_time * num_nodes
        beta_costs = (aws_fee_c1xlarge + service_fee_beta_c1xlarge) * usage_time * num_nodes
        customer_costs = (aws_fee_c1xlarge + service_fee_c1xlarge) * usage_time * num_nodes
    end

    # make discount depend on usage time
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

    # add discount in USD
    real_costs_usd = real_costs
    beta_costs_usd = sprintf('%.2f', beta_costs * discount)
    customer_costs_usd = sprintf('%.2f', customer_costs * discount)

    # calculate Euro from USD prices
    Money.default_bank = Money::Bank::GoogleCurrency.new
    n = real_costs_usd.to_money(:USD)
    real_costs_euro = n.exchange_to(:EUR)
    n = beta_costs_usd.to_money(:USD)
    beta_costs_euro = n.exchange_to(:EUR)
    n = customer_costs_usd.to_money(:USD)
    customer_costs_euro = n.exchange_to(:EUR)

    # add PayPal fees in Euro
    real_costs_euro = sprintf('%.2f', (real_costs_euro.to_f * paypal_percentage + paypal_transaction_fee))
    beta_costs_euro = sprintf('%.2f', (beta_costs_euro.to_f * paypal_percentage + paypal_transaction_fee))
    customer_costs_euro = sprintf('%.2f', (customer_costs_euro.to_f * paypal_percentage + paypal_transaction_fee))

    # calculate USD from Euro prices (just for display)
    Money.default_bank = Money::Bank::GoogleCurrency.new
    n = real_costs_euro.to_money(:EUR)
    real_costs_usd = n.exchange_to(:USD)
    n = beta_costs_euro.to_money(:EUR)
    beta_costs_usd = n.exchange_to(:USD)
    n = customer_costs_euro.to_money(:EUR)
    customer_costs_usd = n.exchange_to(:USD)

    puts "USD costs: "+real_costs_usd.to_s+" "+beta_costs_usd.to_s+" "+customer_costs_usd.to_s
    puts "Euro costs: "+real_costs_euro.to_s+" "+beta_costs_euro.to_s+" "+customer_costs_euro.to_s

    # return lower price for beta users
    if beta_user == true
      return beta_costs_euro
    else
      return customer_costs_euro
    end

  end


end


