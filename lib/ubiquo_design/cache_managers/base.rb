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
          content_id = calculate_content_id(widget_id, options)
          valid = not_expired(widget_id, content_id, options)
          retrieve(content_id) if valid
        end

        # Caches the content of a widget, with a possible expiration date.
        def cache(widget_id, contents, options = {})
          content_id = calculate_content_id(widget_id, options)
          validate(widget_id, content_id, options)
          store(content_id, contents) if content_id
        end

        # Expires the applicable content of a widget given its id
        def expire(widget_id, options = {})
          model_content_id = calculate_content_id(widget_id, options.slice(:scope))
          delete(model_content_id)

          with_instance_content(widget_id, options) do |instance_content_id|
            content_ids = retrieve(instance_content_id)[:content_ids] rescue []
            content_ids.each{|content_id| delete(content_id)}
          end
        end

        protected

        # Calculates a string content identifier depending on the widget
        # +widget+ can be either a Widget instance or a widget id
        # possible options:
        #   policy_context:  cache Policies definition context (default nil)
        #   scope:    object where the params and lambdas will be evaluated
        # Returns nil if the widget should not be cached according to the policies
        def calculate_content_id(widget, options = {})
          widget, policies = policies_for_widget(widget, options)
          return unless policies

          content_id = widget.id.to_s

          unless policies[:params].blank?
            param_ids = policies[:params].map do |param_id|
              "###{param_id}###{options[:scope].send(:params)[param_id]}"
            end
            content_id += '_params_' + param_ids.join
          end

          unless policies[:procs].blank?
            proc_ids = policies[:procs].map do |proc|
              "###{proc.bind(options[:scope]).call}"
            end
            content_id += '_procs_' + proc_ids.join
          end

          content_id
        end

        # retrieves the widget content identified by +content_id+
        def retrieve(content_id)
          raise NotImplementedError.new 'Implement retrieve(content_id) in your CacheManager'
        end

        # Stores a widget content indexing by a +content_id+
        def store(content_id, contents)
          raise NotImplementedError.new 'Implement store(content_id, contents) in your CacheManager'
        end

        # removes the widget content from the store
        def delete(content_id)
          raise NotImplementedError.new 'Implement delete(content_id) in your CacheManager'
        end

        # Returns true if the content_id fragment is not expired and still vigent
        def not_expired(widget, content_id, options)
          with_instance_content(widget, options) do |instance_content_id|
            valid_content_ids = retrieve(instance_content_id)
            return valid_content_ids[:content_ids].include? content_id rescue false
          end

          true
        end

        # Marks the content_id as valid if necessary
        def validate(widget, content_id, options)
          with_instance_content(widget, options) do |instance_content_id|
            valid_content_ids = retrieve(instance_content_id)
            valid_content_ids ||= {}
            (valid_content_ids[:content_ids] ||= []) << content_id
            valid_content_ids[:content_ids].uniq
            store(instance_content_id, valid_content_ids)
          end

        end

        # Wrapper for getting, if applicable, the instance content id,
        # given a Widget instance
        def with_instance_content(widget, options)
          widget, policies = policies_for_widget(widget, options)
          return unless policies

          unless policies[:params].blank?
            if policies[:params].include?(:id) # TODO for slug, url_slug..
              instance_id = if options[:scope].respond_to?(:params)
                options[:scope].send(:params)[:id]
              else
                options[:scope].send(:id)
              end
              instance_content_id = "#{widget.id.to_s}####{instance_id}"
              yield(instance_content_id)
            end
          end
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
