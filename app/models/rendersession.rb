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

    # fees by AWS for t.micro, m1.large, m1.xlarge, c1.xlarge
    af_arr = ENV['CC_AWS_FEES'].split(",")
    aws_fee_t1micro = af_arr[0].to_f
    aws_fee_m1large = af_arr[1].to_f
    aws_fee_m1xlarge = af_arr[2].to_f
    aws_fee_c1xlarge = af_arr[3].to_f

    # service fees for customers
    sf_arr = ENV['CC_SERVICE_FEES'].split(",")
    service_fee_t1micro = sf_arr[0].to_f
    service_fee_m1large = sf_arr[1].to_f
    service_fee_m1xlarge = sf_arr[2].to_f
    service_fee_c1xlarge = sf_arr[3].to_f

    # service fees for beta users
    sbf_arr = ENV['CC_SERVICE_BETA_FEES'].split(",")
    service_fee_beta_t1micro = sbf_arr[0].to_f
    service_fee_beta_m1large = sbf_arr[1].to_f
    service_fee_beta_m1xlarge = sbf_arr[2].to_f
    service_fee_beta_c1xlarge = sbf_arr[3].to_f

    # discounts
    discount_arr = ENV['CC_DISCOUNTS'].split(",")

    # costs are first calculated in USD because AWS fees are in USD
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

    # final costs with discount included
    customer_costs_usd = sprintf('%.2f', customer_costs * discount)
    beta_costs_usd = sprintf('%.2f', beta_costs * discount)

    # convert costs to EUR
    Money.default_bank = Money::Bank::GoogleCurrency.new
    n = customer_costs_usd.to_money(:USD)
    customer_costs_euro = n.exchange_to(:EUR)
    n = beta_costs_usd.to_money(:USD)
    beta_costs_euro = n.exchange_to(:EUR)

    # return lower price for beta users
    if beta_user == true
      return beta_costs_euro
    else
      return customer_costs_euro
    end

  end


end


