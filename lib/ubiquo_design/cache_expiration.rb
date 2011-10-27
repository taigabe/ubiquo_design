module UbiquoDesign
  # This module encapsulates the required hooks to allow expiration of cache
  # in the normal ActiveRecord workflow. This means that every action
  # that should trigger cache expiration is reflected here
  module CacheExpiration

    module ActiveRecord

      def self.append_features(base)
        super
        base.send :include, InstanceMethods
      end

      module InstanceMethods

        def self.included(klass)
          klass.alias_method_chain :create, :cache_expiration
          klass.alias_method_chain :update, :cache_expiration
          klass.alias_method_chain :destroy, :cache_expiration
          attr_accessor :cache_expiration_denied
        end

        def without_cache_expiration
          self.cache_expiration_denied = true
          yield
          self.cache_expiration_denied = false
        end

        def create_with_cache_expiration
          created = create_without_cache_expiration
          expire_by_model if created
          created
        end

        def update_with_cache_expiration
          updated = update_without_cache_expiration
          expire_by_model if updated
          updated
        end

        def destroy_with_cache_expiration
          destroyed = destroy_without_cache_expiration
          expire_by_model if destroyed
          destroyed
        end
        protected

        def expire_by_model
          return if self.cache_expiration_denied.present?
          expirable_widgets, version_widgets = UbiquoDesign::CachePolicies.get_by_model(self, @cache_policy_context)
          expirable_widgets.each do |key|
            Widget.class_by_key(key).all.each do |widget|
              UbiquoDesign.cache_manager.expire(widget,
                :scope => self,
                :policy_context => @cache_policy_context,
                :current_model => self.class.name)
            end
          end
          version_widgets.each do |key|
            key.to_s.classify.constantize.update_all('version = (version +1)')
            Rails.logger.debug "Version cache #{key}, from #{self.id} - #{self.class.name}"
          end
          # TODO if the model contains one of: publication_date, published_at, then expire at that time
        end

      end
    end

  end
end
