module UbiquoDesign
  module Connectors
    class Standard < Base
      
      
      module Component
        
        def self.included(klass)
          klass.send :belongs_to, :block
        end
      end
      
      module Page
        
        def self.included(klass)
          klass.send(:include, self::InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
        end
        
        module InstanceMethods
          
          def uhook_publish_block_components(block, new_block)
            block.components.each do |component|
              new_component = component.clone
              new_component.block = new_block
              new_component.save_without_validation!
              yield component, new_component
              new_component.save! # must validate now
            end
          end
          def uhook_publish_component_asset_relations(component, new_component)
            if component.respond_to?(:asset_relations)
              component.asset_relations.each do |asset_relation|
                new_asset_relation = asset_relation.clone
                new_asset_relation.related_object = new_component
                new_asset_relation.save!
              end
            end
          end
        end
      end
      module PagesController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          # Loads the page for the public part. 
          # Can use params[:category] and params[:url_name] to decide what page to show.
          # Must returns the expected Page instance.
          def uhook_load_page
            ::Page.find_public(params[:category], params[:url_name])
          end
        end
      end

      module UbiquoDesignsHelper
        def self.included(klass)
          klass.send(:helper, Helper)
        end
        module Helper
          def uhook_link_to_edit_component(component)
            link_to t('ubiquo.design.component_edit'), ubiquo_page_design_component_path(@page, component), :class => "edit lightwindow", :type => "page", :params => "lightwindow_form=component_edit_form,lightwindow_width=610", :id => "edit_component_#{component.id}"
          end
          def uhook_load_components(block)
            block.components
          end
        end        
      end
      
      module UbiquoComponentsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          
          # returns the component for the lightwindow. 
          # Will be rendered in their ubiquo/_form view
          def uhook_find_component
            @component = ::Component.find(params[:id])
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
        module Helper
          def uhook_extra_rjs_on_update(page, valid)
            yield page
          end
        end
      end

      module UbiquoMenuItemsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
        end
        module InstanceMethods
          
          # gets Menu items instances for the list and return it
          def uhook_find_menu_items
            ::MenuItem.roots
          end
          
          # initialize a new instance of menu item
          def uhook_new_menu_item
            ::MenuItem.new(:parent_id => (params[:parent_id] || 0), :is_active => true)
          end
          
          # creates a new instance of menu item
          def uhook_create_menu_item
            mi = ::MenuItem.new(params[:menu_item])
            mi.save
            mi
          end
          
          #updates a menu item instance. returns a boolean that means if update was done.
          def uhook_update_menu_item(menu_item)
            menu_item.update_attributes(params[:menu_item])
          end
          
          #destroys a menu item instance. returns a boolean that means if destroy was done.
          def uhook_destroy_menu_item(menu_item)
            menu_item.destroy
          end

          # loads all automatic menu items
          def uhook_load_automatic_menus
            ::AutomaticMenu.find(:all, :order => 'name ASC')  
          end
        end
      end

      module UbiquoPagesController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        
        module Helper
          def uhook_page_actions(page)
            [
              link_to(t('ubiquo.edit'), edit_ubiquo_page_path(page)),
              link_to(t('ubiquo.design.design'), ubiquo_page_design_path(page)),
              link_to(t('ubiquo.remove'), [:ubiquo, page], :confirm => t('ubiquo.design.confirm_page_removal'), :method => :delete)
            ]
          end
          
          def uhook_edit_sidebar
            ""
          end
          def uhook_new_sidebar
            ""
          end
          def uhook_form_top(form)
            ""
          end
        end
        module InstanceMethods
          
          # Returns all private pages
          def uhook_find_private_pages(filters, order_by, sort_order)
            ::Page.public_scope(false) do
              ::Page.filtered_search(filters, :order => order_by + " " + sort_order)
            end            
          end
          
          # initializes a new instance of page.
          def uhook_new_page
            ::Page.new
          end
          
          # create a new instance of page.
          def uhook_create_page
            p = ::Page.new(params[:page])
            p.save
            p
          end
         
          #updates a page instance. returns a boolean that means if update was done.
          def uhook_update_page(page)
            page.update_attributes(params[:page])
          end

          #destroys a page isntance. returns a boolean that means if the destroy was done.
          def uhook_destroy_page(page)
            page.destroy
          end
        end
      end
      
      module RenderPage
        
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, InstanceMethods
        end
        
        module InstanceMethods
          def uhook_collect_components(b, &block)
            b.components.collect(&block)
          end
        end
      end
      
      module Migration
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, ClassMethods
        end
        
        module ClassMethods
          def uhook_create_pages_table
            create_table :pages do |t|
              yield t
            end
          end
          def uhook_create_components_table
            create_table :components do |t|
              yield t
            end
          end
        end
      end
      
    end
  end
end
