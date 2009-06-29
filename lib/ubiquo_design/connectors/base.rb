module UbiquoDesign
  module Connectors
    class Base
      
      # loads this connector. It's called if that connector is used
      def self.load!
        ::Page.send(:include, self::Page)
        ::PagesController.send(:include, self::PagesController)
        ::Ubiquo::ComponentsController.send(:include, self::UbiquoComponentsController)
        ::Ubiquo::MenuItemsController.send(:include, self::UbiquoMenuItemsController)
        ::Ubiquo::PagesController.send(:include, self::UbiquoPagesController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
      end
    end
  end
end 
