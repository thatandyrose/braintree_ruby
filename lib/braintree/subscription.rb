module Braintree
  class Subscription
    include BaseModule

    module Source
      Api          = "api"
      ControlPanel = "control_panel"
      Recurring    = "recurring"
      Unrecognized = "unrecognized"
    end

    module Status
      Active = 'Active'
      Canceled = 'Canceled'
      Expired = 'Expired'
      PastDue = 'Past Due'
      Pending = 'Pending'

      All = constants.map { |c| const_get(c) }
    end

    module TrialDurationUnit
      Day = "day"
      Month = "month"
    end

    attr_reader :days_past_due, :price, :plan_id, :id, :status, :payment_method_token, :merchant_account_id
    attr_reader :first_billing_date, :next_billing_date, :billing_period_start_date, :billing_period_end_date
    attr_reader :paid_through_date, :balance
    attr_reader :trial_period, :trial_duration, :trial_duration_unit
    attr_reader :failure_count
    attr_reader :transactions
    attr_reader :next_billing_period_amount
    attr_reader :number_of_billing_cycles, :billing_day_of_month
    attr_reader :add_ons, :discounts
    attr_reader :descriptor
    attr_reader :current_billing_cycle
    attr_reader :updated_at, :created_at
    attr_reader :status_history

    def self.cancel(subscription_id)
      config.gateway.subscription.cancel(subscription_id)
    end

    def self.create(attributes)
      Configuration.gateway.subscription.create(attributes)
    end

    def self.create!(attributes)
      return_object_or_raise(:subscription) { create(attributes) }
    end

    def self.find(id)
      config.gateway.subscription.find(id)
    end

    def self.retry_charge(subscription_id, amount=nil)
      config.gateway.transaction.retry_subscription_charge(subscription_id, amount)
    end

    # See http://www.braintreepayments.com/docs/ruby/subscriptions/search
    def self.search(config, &block)
      config.gateway.subscription.search(&block)
    end

    def self.update(subscription_id, attributes)
      config.gateway.subscription.update(subscription_id, attributes)
    end

    def self.update!(subscription_id, attributes)
      return_object_or_raise(:subscription) { update(subscription_id, attributes) }
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @balance = Util.to_big_decimal(balance)
      @price = Util.to_big_decimal(price)
      @descriptor = Descriptor.new(@descriptor)
      transactions.map! { |attrs| Transaction._new(gateway, attrs) }
      add_ons.map! { |attrs| AddOn._new(attrs) }
      discounts.map! { |attrs| Discount._new(attrs) }
      @status_history = attributes[:status_history] ? attributes[:status_history].map { |s| StatusDetails.new(s) } : []
    end

    def next_bill_amount
      warn "[DEPRECATED] Subscription.next_bill_amount is deprecated. Please use Subscription.next_billing_period_amount"
      @next_bill_amount
    end

    def never_expires?
      @never_expires
    end

    # True if <tt>other</tt> has the same id.
    def ==(other)
      return false unless other.is_a?(Subscription)
      id == other.id
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
