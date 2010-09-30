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
        end

        def create_with_cache_expiration
          expire_by_model
          create_without_cache_expiration
        end

        def update_with_cache_expiration
          expire_by_model
          update_without_cache_expiration
        end

        protected

        def expire_by_model
          expirable_widgets = UbiquoDesign::CachePolicies.get_by_model(self, @cache_policy_context)
          expirable_widgets.each do |key|
            Widget.class_by_key(key).all.each do |widget|
              UbiquoDesign.cache_manager.expire(widget, :scope => self, :policy_context => @cache_policy_context)
            end
          end
          # TODO if the model contains one of: publication_date, published_at, then expire at that time
        end

      end
    end

  end
end