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
          klass.send :belongs_to, :block, :translation_shared => true
          klass.send :translatable, :options
        end
      end

      module MenuItem
        def self.included(klass)
          klass.send :translatable, :caption
          
          klass.reflections[:children].options[:translation_shared] = true
          klass.reflections[:parent].options[:translation_shared] = true
          
#           klass.send :after_create do |menu_item|
#             if menu_item.is_root?
#               Locale.active.each do |locale|
#                 next if locale.iso_code == menu_item.locale || menu_item.translations.map(&:locale).include?(locale.iso_code)
#                 menu_item.translate(locale, :copy_all => true).save!
#               end
#             end
#           end
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

      module UbiquoDesignsHelper
        def self.included(klass)
          klass.send(:helper, Helper)
        end
        module Helper
          def uhook_link_to_edit_component(component)
            if component.locale == current_locale
              link_to t('ubiquo.design.component_edit'), ubiquo_page_design_component_path(@page, component), :class => "edit lightwindow", :type => "page", :params => "lightwindow_form=component_edit_form,lightwindow_width=610", :id => "edit_component_#{component.id}"
            else
              link_to t('ubiquo.design.component_translate'), ubiquo_page_design_component_path(@page, component), :class => "edit lightwindow", :type => "page", :params => "lightwindow_form=component_edit_form,lightwindow_width=610", :id => "edit_component_#{component.id}"
            end
          end
          def uhook_load_components(block)
            block.components.locale(current_locale, :ALL)
          end
        end        
      end
      
      module UbiquoComponentsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          ComponentTranslation.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          
          # returns the component for the lightwindow. 
          # Will be rendered in their ubiquo/_form view
          def uhook_find_component
            @component = ::Component.locale(current_locale, :ALL).find(params[:id])
          end
          
          # modify the created component and return it. It's executed in drag-drop.
          def uhook_prepare_component(component)
            component.locale = component.component_type.is_configurable? ? current_locale : 'any'
            component
         end
          
          # Destroys a component
          def uhook_destroy_component(component)
            component.destroy_content
          end
          
          # updates a component. 
          # Fields can be found in params[:component] and component_id in params[:id]
          # must returns the updated component
          def uhook_update_component
            component = ::Component.find(params[:id])
            if current_locale != component.locale
              component = component.translate(current_locale, :copy_all => true) 
              component.locale = current_locale
            end
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
            if @component.id
              page.replace "edit_component_#{params[:id]}", uhook_link_to_edit_component(@component)
              page << "myLightWindow._processLink($('edit_component_#{@component.id}'));" if @component.component_type.is_configurable?
            end
          end
        end
      end

      module UbiquoMenuItemsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          ComponentTranslation.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          
          # gets Menu items instances for the list and return it
          def uhook_find_menu_items
            ::MenuItem.locale(current_locale, :ALL).roots
          end
          
          # initialize a new instance of menu item
          def uhook_new_menu_item
            mi = ::MenuItem.translate(params[:from], current_locale, :copy_all => true)
            mi.parent_id = params[:parent_id] || 0
            mi.is_active = true
            mi
          end
          
          def uhook_edit_menu_item(menu_item)
            unless menu_item.locale?(current_locale)
              redirect_to(ubiquo_menu_items_path)
              false
            end   
          end
          
          # creates a new instance of menu item
          def uhook_create_menu_item
            mi = ::MenuItem.new(params[:menu_item])
            mi.locale = current_locale
            if mi.is_root?
              mi.save
            elsif mi.content_id.to_i == 0
              root = mi.parent
              mi.parent_id = nil
              root.children << mi
              root.save
            else
              mi.save
            end
            mi
          end
          
          #updates a menu item instance. returns a boolean that means if update was done.
          def uhook_update_menu_item(menu_item)
            menu_item.update_attributes(params[:menu_item])
          end
          
          #destroys a menu item instance. returns a boolean that means if destroy was done.
          def uhook_destroy_menu_item(menu_item)
            menu_item.destroy_content
          end

          # loads all automatic menu items
          def uhook_load_automatic_menus
            ::AutomaticMenu.find(:all, :order => 'name ASC')  
          end
        end
        
        module Helper
          def uhook_extra_hidden_fields(form)
            form.hidden_field :content_id
          end
          def uhook_menu_item_links(menu_item)
            links = []
            
            if menu_item.locale?(current_locale)
              links << link_to(t("ubiquo.edit"), [:edit, :ubiquo, menu_item])
            else
              links << link_to(
                t("ubiquo.edit"), 
                new_ubiquo_menu_item_path(
                  :from => menu_item.content_id
                  )
                )
            end
            links << link_to(t("ubiquo.remove"), 
              ubiquo_menu_item_path(menu_item, :destroy_content => true), 
              :confirm => t("ubiquo.design.confirm_sitemap_removal"), :method => :delete
              )
            if menu_item.can_have_children?
              links << link_to(t('ubiquo.design.new_subsection'), new_ubiquo_menu_item_path(:parent_id => menu_item))
            end
            
            
            links.join(" | ")
          end
        end
      end



      module RenderPage
        
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          ComponentTranslation.register_uhooks klass, InstanceMethods
        end
        
        module InstanceMethods
          def uhook_collect_components(b, &block)
            b.components.locale(current_locale).collect(&block)
          end
          
          def uhook_root_menu_items
            ::MenuItem.locale(current_locale).roots.active
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
          def uhook_create_menu_items_table
            create_table :menu_items, :translatable => true do |t|
              yield t
            end
          end
        end
      end
      
    end
  end
end
