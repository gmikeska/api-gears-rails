require "api_gears"
require "byebug"

module ApiGearsRails
  module ApiConnection
      extend ActiveSupport::Concern

      included do
        cattr_accessor :api,:parameter_mapping,:api_search_keys,:endpoints
        @@api_search_keys = []
        @@parameter_mapping = {}
        @@endpoints = {}
        @@after_callbacks = {}
        @@after_callbacks = {}
      end

      class_methods do
        def sync_with(api_constant_symbol,**args)
          @@api = api_constant_symbol.to_s.constantize.new(**args)

          if(args[:keys].present?)
            @@api_search_keys = args[:keys]
            args.delete(:keys)
          end
        end
        def sync_attr(attribute_name,**args)
          if(args[:as].nil?)
            @@parameter_mapping[attribute_name.to_sym] = attribute_name.to_sym
          else
            @@parameter_mapping[args[:as].to_sym] = attribute_name.to_sym
          end
        end
        def pull_endpoint(endpoint_name,**args)
          @@endpoints[:pull] = endpoint_name.to_sym
        end
        def push_endpoint(endpoint_name,**args)
          @@endpoints[:push] = endpoint_name.to_sym
        end
        def create_endpoint(endpoint_name,**args)
          @@endpoints[:create] = endpoint_name.to_sym
        end
        def update_endpoint(endpoint_name,**args)
          @@endpoints[:update] = endpoint_name.to_sym
        end
        def destroy_endpoint(endpoint_name,**args)
          @@endpoints[:destroy] = endpoint_name.to_sym
        end
        def before_pull(&proc)
          after_callbacks[:pull] = proc
        end
        def before_push(&proc)
          before_callbacks[:pull] = proc
        end
        def before_create(&proc)
          before_callbacks[:pull] = proc
        end
        def before_read(&proc)
          before_callbacks[:pull] = proc
        end
        def before_update(&proc)
          before_callbacks[:pull] = proc
        end
        def before_destroy(&proc)
          before_callbacks[:pull] = proc
        end
        def after_pull(&proc)
          after_callbacks[:pull] = proc
        end
        def after_push(&proc)
          after_callbacks[:push] = proc
        end
        def after_create(&proc)
          after_callbacks[:create] = proc
        end
        def after_read(&proc)
          after_callbacks[:read] = proc
        end
        def after_update(&proc)
          after_callbacks[:update] = proc
        end
        def after_destroy(&proc)
          after_callbacks[:destroy] = proc
        end
      end
      def run_api_callback(before_after,type,args)
        if(before_after.to_sym = :before)
          callback = before_callbacks[type.to_sym].call(args)
        elsif(before_after.to_sym = :after)
          callback = after_callbacks[type.to_sym]
        end
        if(callback.is_a? Proc)
          callback.call(args)
        else
          self.send(callback.to_sym,args)
        end
      end
      def is_search_key?(key)
        if(@@api_search_keys.is_a? Array)
          return (@@api_search_keys.include?(key))
        else
          return (@@api_search_keys == key)
        end
      end

      def api_push()
        raise NoMethodError.new "no pull endpoint found on #{self.class.name}. Specify an endpoint with 'push_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:push].present?)
        if(@@endpoints[:push])
          params = {}
          @@parameter_mapping.each_pair do |param_name,attr_name|
            params[param_name] = self.send(attr_name)
          end
          response = @@api.send(@@endpoints[:push], params)
          run_callback :after,:push
        end
      end
      def api_pull()
        raise NoMethodError.new "no pull endpoint found on #{self.class.name}. Specify an endpoint with 'pull_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:pull].present?)
        params = {}
        if(@@api_search_keys.is_a? Array)
          @@api_search_keys.each do |key|
            params[key] = self.send(@@parameter_mapping[key])
          end
        else
          params[@@api_search_keys] = self.send(@@parameter_mapping[@@api_search_keys])
        end
        response = @@api.send(@@endpoints[:pull], params)
        @@parameter_mapping.each_pair do |param_name,attr_name|

          if(response.include?(param_name) && !self.is_search_key?(param_name))
            self.send((attr_name.to_s+"=").to_sym, response[param_name])
          elsif(response.include?(param_name.to_s)&& !self.is_search_key?(param_name))
            self.send((attr_name.to_s+"=").to_sym, response[param_name.to_s])
          end
        end
        run_callback :after,:pull
        self.save()
      end
      def api_create()
        raise NoMethodError.new "no create or push endpoint found on #{self.class.name}. Specify an endpoint with 'push_endpoint :endpoint_name' or 'create_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:create].present? || @@endpoints[:push].present?)
        params = {}
        @@parameter_mapping.each_pair do |param_name,attr_name|
          params[param_name] = self.send(attr_name)
        end
        if(@@endpoints[:create].nil? && @@endpoints[:push].present?)
          return @@api.send(@@endpoints[:push], params)
        elsif(@@endpoints[:create].present? && @@endpoints[:push].nil?)
          return @@api.send(@@endpoints[:create], params)
        end
        run_callback :after,:create
      end
      def api_update()
        raise NoMethodError.new "no api_update or push endpoint found on #{self.class.name}. Specify an endpoint with 'push_endpoint :endpoint_name' or 'update_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:update].present? || @@endpoints[:push].present?)
        params = {}
        @@parameter_mapping.each_pair do |param_name,attr_name|
          params[param_name] = self.send(attr_name)
        end
        if(@@endpoints[:update].nil? && @@endpoints[:push].present?)
          return @@api.send(@@endpoints[:push], params)
        elsif(@@endpoints[:update].present? && @@endpoints[:push].nil?)
          return @@api.send(@@endpoints[:update], params)
        end
        run_callback :after,:update
      end
      def api_destroy()
        raise NoMethodError.new "no api_update or push endpoint found on #{self.class.name}. Specify an endpoint with 'push_endpoint :endpoint_name' or 'update_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:destroy].present?)
        params = {}
        @@parameter_mapping.each_pair do |param_name,attr_name|
          params[param_name] = self.send(attr_name)
        end
        if(@@endpoints[:update].nil? && @@endpoints[:push].present?)
          return @@api.send(@@endpoints[:push], params)
        elsif(@@endpoints[:update].present? && @@endpoints[:push].nil?)
          return @@api.send(@@endpoints[:update], params)
        end
        run_callback :after,:destroy
      end
      def api_read()
        raise NoMethodError.new "no read or pull endpoint found on #{self.class.name}. Specify an endpoint with 'pull_endpoint :endpoint_name' or 'read_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:pull].present?)
        params = {}
        if(@@api_search_keys.is_a? Array)
          @@api_search_keys.each do |key|
            params[key] = self.send(@@parameter_mapping[key])
          end
        else
          params[@@api_search_keys] = self.send(@@parameter_mapping[@@api_search_keys])
        end
        response = @@api.send(@@endpoints[:read], params)
        @@parameter_mapping.each_pair do |param_name,attr_name|

          if(response.include?(param_name) && !self.is_search_key?(param_name))
            self.send((attr_name.to_s+"=").to_sym, response[param_name])
          elsif(response.include?(param_name.to_s)&& !self.is_search_key?(param_name))
            self.send((attr_name.to_s+"=").to_sym, response[param_name.to_s])
          end
        end
        run_callback :after,:read
        self.save()
      end
  end
end

ActiveRecord::Base.send :include, ApiGearsRails::ApiConnection
