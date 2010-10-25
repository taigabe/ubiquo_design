# Manages the declaration of widget cache policies
module UbiquoDesign
  module CachePolicies

    @@policies  ||= {}

    class << self

      # Starts the definition of widget cache policies
      #   context: possible context to create multiple policies
      def define(context = nil, &block)
        with_scope(context) do
          store_definition(block.call || {})
        end
      end

      # Returns a hash with the stored policies
      def get(context = nil)
        with_scope(context) do
          current_base
        end
      end

      # Returns a list of widget types which have policies that affect a given +instance+
      def get_by_model(instance, context = nil)
        (widgets = []).tap do
          get(context).each_pair do |widget, policies|
            if (policies[:models] || []).to_a.detect{|model| instance.is_a?(model.first.to_s.constantize)}
              widgets << widget
            end
          end
        end
      end

      # Sets the current context during a declaration
      def with_scope(scope)
        (@@scopes ||= []) << scope
        yield ensure @@scopes.pop
      end

      # Cleans the current structure
      #   context: possible context for multiple structures
      def clear(context = nil)
        with_scope(context) { current_base.clear }
      end

      # Stores a hash with widget cache policies
      def store_definition policies
        base = current_base
        policies.each_pair do |widget, conditions|
          policy = base[widget] || {
            :self => true,
            :params => [],
            :models => {},
            :procs => []
          }
          add_conditions(policy, conditions)
          base[widget] = policy
        end
      end

      # Adds the +conditions+ to the current widget cache +policy+
      def add_conditions policy, conditions, current_model = nil
        case conditions
        when Symbol
          if conditions == :self
            policy[:self] = true
          else
            if current_model.present?
              policy[:models][current_model][:params] << conditions
              if policy[:models][current_model][:identifier].blank?
                policy[:models][current_model][:identifier] = conditions
              end
            else
              policy[:params] << conditions
            end
          end
        when Proc
          if current_model.present?
            policy[:models][current_model][:procs] << conditions
          else
            policy[:procs] << conditions
          end
        when String
          policy[:models][conditions] = {:params => [],
            :procs => [],
            :identifier => nil}
          current_model = conditions
        when Class
          policy[:models][conditions.name] = {:params => [],
            :procs => [],
            :identifier => nil}
          current_model = conditions.name
        when Array
          c_model = nil
          conditions.each do |condition|
            case condition
            when String
              policy[:models][condition] = {:params => [],
                :procs => [],
                :identifier => nil}
              c_model = condition
            when Class
              policy[:models][condition.name] = {:params => [],
                :procs => [],
                :identifier => nil}
              c_model = condition.name
            when Array
              add_conditions(policy, condition)
            else
              add_conditions(policy, condition, c_model)
            end
          end
        when Hash
          if(conditions.keys.first.is_a?(Symbol) &&
              conditions.keys.first == :identifier)
            policy[:models][current_model][:identifier] = conditions.values.first
          end
          case conditions.values.first
          when Symbol
            if current_model.present?
              policy[:models][current_model][:params] << conditions
              if policy[:models][current_model][:identifier].blank?
                policy[:models][current_model][:identifier] = conditions
              end
            else
              policy[:params] << conditions
            end
          when Array
            if current_model.present?
              policy[:models][current_model][:procs] << conditions.values.first
            else
              policy[:procs] << conditions.values.first
            end
          end
        end
      end

      # Returns the current base hash, given the applied scopes
      def current_base
        current = @@policies
        @@scopes.each do |scope|
          next unless scope
          current[scope] = {} unless current[scope]
          current = current[scope]
        end
        current
      end

    end
  end

end
