module UbiquoDesign

  # Return the manager class to use. You can override the default by setting
  # the :cache_manager_class in ubiquo config:
  #   Ubiquo::Config.context(:ubiquo_design).set(
  #     :cache_manager_class,
  #     UbiquoDesign::CacheManagers::Memcache
  #   )
  def self.cache_manager
    Ubiquo::Config.context(:ubiquo_design).call(:cache_manager_class, self)
  end

  module CacheManagers
    # Base class for widget cache
    class Base
      class << self

        # Gets the cached content of a widget. Returns false if this widget is not
        # currently cached
        def get(widget_id, options = {})
          if (key = calculate_key(widget_id, options))
            valid = not_expired(widget_id, key, options)
            if valid
              cached_content = retrieve(key)
              if cached_content
                Rails.logger.debug "Widget cache hit for widget: #{widget_id.to_s} with key #{key}"
              else
                Rails.logger.debug "Widget cache miss for widget: #{widget_id.to_s} with key #{key}"
              end
              cached_content
            end
          end
        end

        # Caches the content of a widget, with a possible expiration date.
        def cache(widget_id, contents, options = {})
          key = calculate_key(widget_id, options)
          validate(widget_id, key, options)
          if key
            Rails.logger.debug "Widget cache store request sent for widget: #{widget_id.to_s} with key #{key}"
            store(key, contents)
          else
            Rails.logger.debug "Widget cache missing policies for widget: #{widget_id.to_s}"
          end
        end

        # Expires the applicable content of a widget given its id
        def expire(widget_id, options = {})
          model_key = calculate_key(widget_id, options.slice(:scope))
          delete(model_key) if model_key

          with_instance_content(widget_id, options) do |instance_key|
            keys = retrieve(instance_key)[:keys] rescue []
            keys.each{|key| delete(key)}
            delete(instance_key)
          end
        end

        protected

        # Calculates a string content identifier depending on the widget
        # +widget+ can be either a Widget instance or a widget id
        # possible options:
        #   policy_context:  cache Policies definition context (default nil)
        #   scope:    object where the params and lambdas will be evaluated
        # Returns nil if the widget should not be cached according to the policies
        def calculate_key(widget, options = {})
          widget, policies = policies_for_widget(widget, options)
          return unless policies
          key = widget.id.to_s
          options[:widget] = widget
          policies[:models].each do |_key, val|
            if options[:scope].respond_to?(:params) || _key == options[:scope].class.name
              key += process_params(policies[:models][_key], options)
              key += process_procs(policies[:models][_key], options)
            end
          end
          if options[:scope].respond_to?(:params)
            key += process_params(policies, options)
            key += process_procs(policies, options)
          end
          key
        end

        def process_params policies, options
          params_key = ''
          unless policies[:params].blank?
            param_ids = policies[:params].map do |param_id_raw|
              param_id, t_param_id = case param_id_raw
              when Symbol
                [param_id_raw, param_id_raw]
              when Hash
                if options[:scope].respond_to?(:params)
                  [param_id_raw.keys.first(),
                   param_id_raw.keys.first()]
                else
                  [param_id_raw.keys.first(),
                   param_id_raw.values.first()]
                end
              end
              if options[:scope].respond_to?(:params)
                "###{param_id}###{options[:scope].send(:params)[t_param_id]}"
              else
                "###{param_id}###{options[:scope].send(t_param_id)}"
              end
            end
            params_key = '_params_' + param_ids.join
          end
          params_key
        end

        def process_procs policies, options
          procs_key = ''
          if policies[:procs].present?
            proc_ids = policies[:procs].map do |proc_raw|
              proc = case proc_raw
              when Proc
                next unless options[:scope].respond_to?(:params)
                proc_raw
              when Array
                if options[:scope].respond_to?(:params)
                  proc_raw.first
                else
                  proc_raw.last
                end
              end
              if proc.is_a?(Proc)
                "###{proc.bind(options[:scope]).call(options[:widget])}"
              elsif proc.is_a?(Symbol)
                if options[:scope].respond_to?(:params)
                  "###{options[:scope].send(:params)[proc]}"
                else
                  "###{options[:scope].send(proc)}"
                end
              end
            end
            procs_key = '_procs_' + proc_ids.join if proc_ids.compact.present?
          end
          procs_key
        end

        # retrieves the widget content identified by +key+
        def retrieve(key)
          raise NotImplementedError.new 'Implement retrieve(key) in your CacheManager'
        end

        # Stores a widget content indexing by a +key+
        def store(key, contents)
          raise NotImplementedError.new 'Implement store(key, contents) in your CacheManager'
        end

        # removes the widget content from the store
        def delete(key)
          raise NotImplementedError.new 'Implement delete(key) in your CacheManager'
        end

        # Returns true if the key fragment is not expired and still vigent
        def not_expired(widget, key, options)
          with_instance_content(widget, options) do |instance_key|
            valid_keys = retrieve(instance_key)
            return valid_keys[:keys].include? key rescue false
          end
          true
        end

        # Marks the key as valid if necessary
        def validate(widget, key, options)
          with_instance_content(widget, options) do |instance_key|
            valid_keys = retrieve(instance_key)
            valid_keys ||= {}
            (valid_keys[:keys] ||= []) << key
            valid_keys[:keys].uniq
            store(instance_key, valid_keys)
          end

        end

        # Wrapper for getting, if applicable, the instance content id,
        # given a Widget instance
        def with_instance_content(widget, options)
          widget, policies = policies_for_widget(widget, options)
          return unless policies

          widget_pre_key = "__" + (widget.is_a?(Widget) ? widget.id.to_s : widget.to_s )
          if policies[:models].present?
            policies[:models].each do |key, val|
              if options[:current_model].present? && options[:current_model].to_s != key.to_s
                next
              end
              if val[:identifier].is_a?(Hash)
                if options[:scope].respond_to?(:params)
                  true_identifier = val[:identifier].keys.first
                else
                  true_identifier = val[:identifier].values.first
                end
              elsif val[:identifier].is_a?(Array)
                if options[:scope].respond_to?(:params)
                  true_identifier = val[:identifier].first
                else
                  true_identifier = val[:identifier].last
                end
              else
                true_identifier = val[:identifier]
              end

              p_i = if true_identifier.blank?
                "_#{key.to_s}"
              elsif options[:scope].respond_to?(:params)
                if true_identifier.is_a? Proc
                  "_#{key.to_s}_#{true_identifier.bind(options[:scope]).call(options[:widget])}"
                else
                  "_#{key.to_s}_#{options[:scope].send(:params)[true_identifier]}"
                end
              else
                "_#{key.to_s}_#{options[:scope].send(true_identifier)}"
              end

              yield(widget_pre_key + p_i)
            end
          else
            yield(widget_pre_key)
          end
          return

        end

        # Returns a widget and its policies ([widget, policies])
        # for a given widget or widget_id

        def policies_for_widget widget, options
          widget = widget.is_a?(Widget) ? widget : Widget.find(widget)
          policies = UbiquoDesign::CachePolicies.get(options[:policy_context])[widget.key]
          [widget, policies]
        end

      end
    end
  end
end
