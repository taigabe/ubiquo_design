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

      # Returns a hash with the required policies
      def get(context = nil)
        with_scope(context) do
          current_base
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
            :models => [],
            :procs => []
          }
          add_conditions(policy, conditions)
          base[widget] = policy
        end
      end

      # Adds the +conditions+ to the current widget cache +policy+
      def add_conditions policy, conditions
        case conditions
        when String, Symbol
          if conditions == :self
            policy[:self] = true
          else
            policy[:params] << conditions
          end
        when Proc
          policy[:procs] << conditions
        when Class
          policy[:models] << conditions
        when Array
          conditions.each{|condition| add_conditions(policy, condition)}
        when Hash
          conditions.each_pair do |key, condition|
            condition = Array(condition) unless key == :self
            policy[key] = condition
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
