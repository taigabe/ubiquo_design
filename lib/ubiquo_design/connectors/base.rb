module UbiquoDesign
  module Connectors
    class Base
      
      # loads this connector. It's called if that connector is used
      def self.load!
        begin
          ::Page.send(:include, self::Page) if self.constants.include?("Page")
        rescue NameError; end
        begin
          ::Component.send(:include, self::Component) if self.constants.include?("Component")
        rescue NameError; end
        begin
          ::PagesController.send(:include, self::PagesController) if self.constants.include?("PagesController")
        rescue NameError; end
        begin
          ::Ubiquo::ComponentsController.send(:include, self::UbiquoComponentsController) if self.constants.include?("UbiquoComponentsController")
        rescue NameError; end
        begin
          ::Ubiquo::MenuItemsController.send(:include, self::UbiquoMenuItemsController) if self.constants.include?("UbiquoMenuItemsController")
        rescue NameError; end
        begin
          ::Ubiquo::PagesController.send(:include, self::UbiquoPagesController) if self.constants.include?("UbiquoPagesController")
        rescue NameError; end
        begin
          ::ActiveRecord::Migration.send(:include, self::Migration) if self.constants.include?("Migration")
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
