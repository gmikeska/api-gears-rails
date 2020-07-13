require "api_gears"

module ApiGearsRails
  module ApiConnection
      extend ActiveSupport::Concern

      included do
        cattr_accessor :api,:parameter_mapping,:api_search_keys,:endpoints,:api_verbs,:push_timeout,:pull_timeout,:sync_timeout,:auto_api_sync
        @@api_search_keys = []
        @@parameter_mapping = {}
        @@endpoints = {}
      end

    class_methods do
      @@api_verbs = {push:[:push,:create,:update,:destroy],pull:[:pull,:read]}
      @@after_callbacks = {}
      @@before_callbacks = {}
      @@pull_timeout = nil
      @@push_timeout = nil
      @@sync_timeout = nil
      @@auto_api_sync = nil

      # Specifies API class to be used for synchronization. Sets api_search_keys which are keys that must be passed when calling api.
      #
      # @param api_constant_symbol [Symbol] the name of the ApiGears subclass to instantiate (as a symbol)
      # @param args [Hash] the initialization args to be passed when instantiating the ApiGears instance. Also specify args to be passed for queries using args[:keys]
      def sync_with(api_constant_symbol,**args)
        @@api = api_constant_symbol.to_s.constantize.new(**args)

        if(args[:keys].present?)
          @@api_search_keys = args[:keys]
          args.delete(:keys)
        end
      end

      # Specifies which verbs should be automatically invoked when actions are performed on a model instance.
      #
      # @param args [Hash] pass nill value to specify auto-sync of all defined verbs, pass only:[] or except:[] to specify or skip certain verbs respectively.
      def auto_sync(**args)
        if(args.nil?)
          @@auto_api_sync = @@endpoints.keys
        end
        if(args[:except]).present
          @@auto_api_sync = @@endpoints.keys.select{|k| !args[:except].include?(k)}
        end
        if(args[:only]).present
          @@auto_api_sync = args[:only]
        end
        if(@@auto_api_sync.include?(:create) && @@endpoints.keys.include?(:create))
          self.after_create do |record|
            record.api_create
          end
        elsif(@@auto_api_sync.include?(:create) && @endpoints.keys.include(:push))
          self.after_create do |record|
            record.api_push
          end
        end
        if(@@auto_api_sync.include?(:read) && @@endpoints.keys.include?(:read))
          self.after_create do |record|
            record.api_pull
          end
        elsif(@@auto_api_sync.include?(:read) && @endpoints.keys.include(:pull))
          self.after_create do |record|
            record.api_pull
          end
        end
        if(@@auto_api_sync.include?(:update) && @@endpoints.keys.include?(:update))
          self.after_update do |record|
            record.api_update
          end
        elsif(@@auto_api_sync.include?(:update) && @endpoints.keys.include(:push))
          self.after_create do |record|
            record.api_push
          end
        end
        if(@@auto_api_sync.include?(:destroy) && @@endpoints.keys.include?(:destroy))
          self.after_destroy do |record|
            record.api_destroy
          end
        end
        if(@@auto_api_sync.include?(:pull) && @@endpoints.keys.include?(:pull))
          self.after_initialize do |record|
            record.api_pull
          end
        end
        if(@@auto_api_sync.include?(:push) && @@endpoints.keys.include?(:push))
          self.after_save do |record|
            record.api_push
          end
        end
      end
      # Sets a time interval for push sync operations.
      #
      # @param time_period [Duration]
      def push_every(time_period)
        @@push_timeout = time_period
      end
      # Sets a time interval for pull sync operations.
      #
      # @param time_period [Duration]
      def pull_every(time_period)
        @@pull_timeout = time_period
      end
      # Sets a time interval for all sync operations.
      #
      # @param time_period [Duration]
      def sync_every(time_period)
        @@sync_timeout = time_period
      end
      # Specifies the data key that is associated with a particular model attribute
      # @param attribute_name [String] or [Symbol] local name of attribute
      # @param args [Hash] include hash key "as:" to specify the key name used when pushing to or pulling from the API.
      def sync_attr(attribute_name,**args)
        if(args[:as].nil?)
          @@parameter_mapping[attribute_name.to_sym] = attribute_name.to_sym
        else
          @@parameter_mapping[attribute_name.to_sym] = args[:as].to_sym
        end
      end
      @@api_verbs[:push].concat(@@api_verbs[:pull]).each do |verb|
        define_method (verb.to_s+"_endpoint").to_sym do |endpoint_name,**args|
          @@endpoints[verb.to_sym] = endpoint_name.to_sym
        end
        define_method ("before_api_"+verb.to_s).to_sym do |&proc|
          @@before_callbacks[verb.to_sym] = proc
        end
        define_method ("after_api_"+verb.to_s).to_sym do |&proc|
          @@after_callbacks[verb.to_sym] = proc
        end
      end
      @@api_verbs[:push].each do |verb|
        define_method ('api_'+verb.to_s).to_sym do |verb,**args|
          self.api_push(verb= verb)
        end
      end
      @@api_verbs[:pull].each do |verb|
        define_method ('api_'+verb.to_s).to_sym do |verb,**args|
          self.api_pull(verb= verb)
        end
      end
    end
    def run_api_callback(before_after,type,data)
      if(before_after.to_sym == :before)
        callback = @@before_callbacks[type.to_sym]
      elsif(before_after.to_sym == :after)
        callback = @@after_callbacks[type.to_sym]
      end
      if(callback.present? && callback.is_a?(Proc))
        data =  callback.yield(data,self)
      elsif(callback.present?)
        data =  self.send(callback,data,self)
      end
      return data
    end
    def is_search_key?(key)
      if(@@api_search_keys.is_a? Array)
        return (@@api_search_keys.include?(key))
      else
        return (@@api_search_keys == key)
      end
    end

    def api_push(verb=:push)
      raise NoMethodError.new "no #{verb.to_s} endpoint found on #{self.class.name}. Specify an endpoint with '#{verb.to_s}_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:push].present?)
      if(@@push_timeout.present? || @@sync_timeout.present?)
        if(@@push_timeout.present?)
          timeout = @@push_timeout
        elsif(@@sync_timeout.present?)
          timeout = @@sync_timeout
        end
        if(self.respond_to? :synced_at)
          timestamp = self.synced_at
        end
        if(self.respond_to? :pushed_at)
          timestamp = self.pushed_at
        end
        if(timeout.present? && timestamp.present? && !((Time.now - timestamp) > timeout))
          return false
        end
      end

      if(@@endpoints[:push])
        params = {}
        @@parameter_mapping.each_pair do |param_name,attr_name|
          params[param_name] = self.send(attr_name)
        end
        if(@@before_callbacks[verb].present?)
          params = run_api_callback(:before,verb,params)
        end
        if(verb != :push && @@before_callbacks[:push].present?)
          params = run_api_callback(:before,:push,params)
        end
        required_params = @@api.args_for(@@endpoints[verb])
        required_params.each do |param|
          if(!parameter_mapping.values.include?(param))
            raise ArgumentError.new "#{@@endpoints[verb].to_s} requires #{param.to_s} which is not mapped to an attribute on #{self.class.name}."
          end
        end
        response = @@api.send(@@endpoints[verb], params)
        if(@@after_callbacks[verb].present?)
          run_api_callback(:after,verb,response)
        end
        if(verb != :push && @@after_callbacks[:push].present?)
          response = run_api_callback(:after,:push,response)
        end
        if(self.respond_to? :synced_at)
          self.synced_at = Time.now
        end
        if(self.respond_to? :pushed_at)
          self.pushed_at = Time.now
        end
        return response
      end
    end
    def api_pull(verb=:pull)
      raise NoMethodError.new "no #{verb.to_s} endpoint found on #{self.class.name}. Specify an endpoint with '#{verb.to_s}_endpoint :endpoint_name' in the class declaration." unless (@@endpoints[:pull].present?)
      if(@@pull_timeout.present? || @@sync_timeout.present?)
        if(@@pull_timeout.present?)
          timeout = @@pull_timeout
        elsif(@@sync_timeout.present?)
          timeout = @@sync_timeout
        end
        if(self.respond_to? :synced_at)
          timestamp = self.synced_at
        end
        if(self.respond_to? :pulled_at)
          timestamp = self.pulled_at
        end
        if(timeout.present? && timestamp.present? && !((Time.now - timestamp) > timeout))
          return false
        end
      end
      params = {}
      if(@@api_search_keys.is_a? Array)
        @@api_search_keys.each do |key|
          params[@@parameter_mapping[key]] = self.send(key)
        end
      else
        params[@@parameter_mapping[@@api_search_keys]] = self.send(@@api_search_keys)
      end
      if(@@before_callbacks[verb].present?)
        params = run_api_callback(:before,verb,params)
      end
      if(verb != :pull && @@before_callbacks[:pull].present?)
        params = run_api_callback(:before,:pull,params)
      end
      required_params = @@api.args_for(@@endpoints[verb])
      required_params.each do |param|
        if(parameter_mapping.values.present? && !parameter_mapping.values.include?(param))
          raise ArgumentError.new "#{@@endpoints[verb].to_s} requires #{param.to_s} which is not mapped to an attribute on #{self.class.name}."
        end
      end
      response = @@api.send(@@endpoints[verb], params)
      if(@@after_callbacks[verb].present?)
        response = run_api_callback(:after,verb,response)
      end
      if(verb != :pull && @@after_callbacks[:pull].present?)
        response = run_api_callback(:after,:pull,response)
      end
      @@parameter_mapping.each_pair do |attr_name,param_name|
        if(response.include?(param_name) && !self.is_search_key?(param_name))
          self.send((attr_name.to_s+"=").to_sym, response[param_name])
        elsif(response.include?(param_name.to_s)&& !self.is_search_key?(param_name))
          self.send((attr_name.to_s+"=").to_sym, response[param_name.to_s])
        end
      end
      if(self.respond_to? :synced_at)
        self.synced_at = Time.now
      end
      if(self.respond_to? :pulled_at)
        self.pulled_at = Time.now
      end
      self.save()
    end
  end
end

ActiveRecord::Base.send :include, ApiGearsRails::ApiConnection
