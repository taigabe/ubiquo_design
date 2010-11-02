module UbiquoDesign
  module Connectors
    class Base

      # loads this connector. It's called if that connector is used
      def self.load!
        [::Widget, ::MenuItem].each(&:reset_column_information)
        if current = UbiquoDesign::Connectors::Base.current_connector
          current.unload!
        end
        validate_requirements
        ::Page.send(:include, self::Page)
        ::PagesController.send(:include, self::PagesController)
        ::Ubiquo::DesignsController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::WidgetsController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::BlocksController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::WidgetsController.send(:include, self::UbiquoWidgetsController)
        ::Ubiquo::MenuItemsController.send(:include, self::UbiquoMenuItemsController)
        ::Ubiquo::StaticPagesController.send(:include, self::UbiquoStaticPagesController)
        ::Ubiquo::PagesController.send(:include, self::UbiquoPagesController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
        ::UbiquoDesign::RenderPage.send(:include, self::RenderPage)
        UbiquoDesign::Connectors::Base.set_current_connector self
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
              connector.send :undef_method, connectorized_method
            end
          end
        end
      end

      def self.current_connector
        @current_connector
      end

      def self.set_current_connector klass
        @current_connector = klass
      end

      # Possible cleanups to perform
      def self.unload!; end

      # Validate here the possible connector requirements and dependencies
      def self.validate_requirements; end
    end

    # Raised when a connector requirement is not met
    class ConnectorRequirementError < StandardError; end
  end
end
