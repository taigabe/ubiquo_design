module UbiquoDesign
  module Connectors
    class Base
      
      # loads this connector. It's called if that connector is used
      def self.load!
        begin
          ::Page.send(:include, self::Page)
        rescue NameError; end
        begin
          ::Component.send(:include, self::Component)
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
    end
  end
end 
