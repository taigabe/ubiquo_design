# Manages the declaration of block structures
module UbiquoDesign
  module Structure

    @@structures  ||= {}

    class << self

      # Starts the definition of an structure
      #   context: possible context to create multiple structures
      def define(context = nil, &block)
        @@structures[context] ||= {} if context
        with_scope(context) do
          yield_inside(&block)
        end
      end

      # Returns a hash with the required structure
      #   options: can contain multiple values:
      #            nil (default): returns the whole structure
      def get(options = nil)
        case options
        when NilClass
          @@structures[options]
        when String, Symbol
          @@structures[options.to_sym]
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
        get(context).clear
      end

      # Yields a block with this module binding
      def yield_inside(&block)
        block.bind(self).call
      end

      # Catches all the possible calls and stores them
      def method_missing(method, *args, &block)
        scope = scope_name(method)
        store_definition scope, args
        with_scope(scope, &block) if block_given?
      end

      # Stores an invocation definition
      def store_definition method, args
        current = @@structures
        @@scopes.each do |scope|
          current = current[scope]
        end
        (current[scope_name(method)] ||= []).concat args
      end

      # Homogenizes a scope name to a pluralized symbol
      def scope_name name
        name.to_s.pluralize.to_sym
      end
    end
  end
end