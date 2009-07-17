module UbiquoDesign
  module Connectors
    class Base
      
      # loads this connector. It's called if that connector is used
      def self.load!
        begin
          ::Page.send(:include, self::Page)
        rescue NameError; end
        begin
          ::PagesController.send(:include, self::PagesController)
        rescue NameError; end
        begin
          ::Ubiquo::ComponentsController.send(:include, self::UbiquoComponentsController)
        rescue NameError; end
        begin
          ::Ubiquo::MenuItemsController.send(:include, self::UbiquoMenuItemsController)
        rescue NameError; end
        begin
          ::Ubiquo::PagesController.send(:include, self::UbiquoPagesController)
        rescue NameError; end
        begin
          ::ActiveRecord::Migration.send(:include, self::Migration)
        rescue NameError; end
      end
      
      # Register the uhooks methods in connectors to be used in klass
      def self.register_uhooks klass, *connectors
        connectors.each do |connector|
          connector.instance_methods.each do |method|
            if method =~ /^uhook_(.*)$/
              connectorized_method = "uhook_#{self.to_s.demodulize.underscore}_#{$~[1]}"
              connector.send :alias_method, connectorized_method, method
              if klass.instance_methods.include?(method)
                klass.send :alias_method, method, connectorized_method
              else
                class << klass
                  self
                end.send :alias_method, method, connectorized_method              
              end
            end
          end
        end
      end
    end
  end
end 
