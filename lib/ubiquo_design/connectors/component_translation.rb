module UbiquoDesign
  module Connectors
    class ComponentTranslation < Base
      
      def self.load!
        Standard.load!
        
        ::PagesController.send(:include, UbiquoI18n::Extensions::LocaleChanger)
        ::PagesController.send(:helper, UbiquoI18n::Extensions::Helpers)
        super
      end
      
      module Component
        
        def self.included(klass)
          klass.send :translatable, :options
          Free.send :translatable, :options
        end
      end
      
      module Page
        
        def self.included(klass)
          klass.send(:include, self::InstanceMethods)
          ComponentTranslation.register_uhooks klass, InstanceMethods
        end
        module InstanceMethods
          
          def uhook_publish_block_components(block, new_block)
            mapped_content_ids = {}
            block.components.each do |component|
              next_content_id = mapped_content_ids[component.content_id]
              
              new_component = component.clone
              new_component.block = new_block
              new_component.content_id = next_content_id
              new_component.save_without_validation!
              
              mapped_content_ids[component.content_id] = new_component.content_id
              
              yield component, new_component
              
              new_component.save! # must validate now
            end
          end
        end
      end
      
      module UbiquoComponentsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          ComponentTranslation.register_uhooks klass, InstanceMethods
        end
        module InstanceMethods
          
          # returns the component for the lightwindow. 
          # Will be rendered in their ubiquo/_form view
          def uhook_find_component
            @component = ::Component.locale(current_locale).find(params[:id])
          end
          
          # modify the created component and return it. It's executed in drag-drop.
          def uhook_prepare_component(component)
            component
         end
          
          # Destroys a component
          def uhook_destroy_component(component)
            component.destroy
          end
          
          # updates a component. 
          # Fields can be found in params[:component] and component_id in params[:id]
          # must returns the updated component
          def uhook_update_component
            component = ::Component.find(params[:id])
            params[:component].each do |field, value|
              component.send("#{field}=", value)
            end
            component.save
            component
          end
          
        end
      end
      
      module Migration
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
          ComponentTranslation.register_uhooks klass, ClassMethods
        end
        
        module ClassMethods
          def uhook_create_components_table
            create_table :components, :translatable => true do |t|
              yield t
            end
          end
        end
      end
      
    end
  end
end
