# Base class for widget cache
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
    class Base
      class << self

        # Gets the cached content of a widget. Returns false if this widget is not
        # currently cached
        def get(widget_id, options = {})
          content_id = calculate_content_id(widget_id, options)
          retrieve(content_id)
        end

        # Caches the content of a widget, with a possible expiration date.
        def cache(widget_id, contents, expires_at = nil, options = {})
          content_id = calculate_content_id(widget_id, options)
          store(content_id, contents)
        end

        # Expires a widget given its id
        def expire(widget_id, options = {})
          content_id = calculate_content_id(widget_id, options)
          delete(content_id)
        end

        protected

        # Calculates a string content identifier depending on the widget_id
        # possible options:
        #   policy_context:  cache Policies definition context (default nil)
        #   scope:    object where the params and lambdas will be evaluated
        def calculate_content_id(widget_id, options = {})
          widget = ::Widget.find(widget_id)
          policies = UbiquoDesign::CachePolicies.get(options[:policy_context])[widget.key]
          content_id = widget_id.to_s

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

      end
    end
  end
end
