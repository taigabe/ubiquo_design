module UbiquoDesign
  module Connectors
    class I18n < Standard

      def self.load!
        super
        ::Widget.send(:include, self::Widget)
        ::MenuItem.send(:include, self::MenuItem)
        ::PagesController.send(:include, UbiquoI18n::Extensions::LocaleChanger)
        ::PagesController.send(:helper, UbiquoI18n::Extensions::Helpers)
      end

      # Validates the ubiquo_i18n-related dependencies
      def self.validate_requirements
        unless Ubiquo::Plugin.registered[:ubiquo_i18n]
          raise ConnectorRequirementError, "You need the ubiquo_i18n plugin to load #{self}"
        end
        [::Widget, ::MenuItem].each do |klass|
          if klass.table_exists?
            klass.reset_column_information
            columns = klass.columns.map(&:name).map(&:to_sym)
            unless [:locale, :content_id].all?{|field| columns.include? field}
              if Rails.env.test?
                ::ActiveRecord::Base.connection.change_table(klass.table_name, :translatable => true){}
                klass.reset_column_information
              else
                raise ConnectorRequirementError,
                  "The #{klass.table_name} table does not have the i18n fields. " +
                  "To use this connector, update the table enabling :translatable => true"
              end
            end
          end
        end
      end

      def self.unload!
        # TODO create generic methods for these cleanups
        [::Widget, ::MenuItem].each do |klass|
          klass.instance_variable_set :@translatable, false
        end
        ::Widget.send :alias_method, :block, :block_without_shared_translations
        ::MenuItem.send :alias_method, :children, :children_without_shared_translations
        ::MenuItem.send :alias_method, :parent, :parent_without_shared_translations
        # Unfortunately there's no neat way to clear the helpers mess
        %w{Widgets MenuItems}.each do |controller_name|
          ::Ubiquo.send(:remove_const, "#{controller_name}Controller")
          load "ubiquo/#{controller_name.tableize}_controller.rb"
        end
      end

      module Widget
        def self.included(klass)
          klass.send :translatable, :options
          klass.share_translations_for :block
        end
      end

      module MenuItem
        def self.included(klass)
          klass.send :translatable, :caption
          klass.share_translations_for :children, :parent
        end
      end

      module Page

        def self.included(klass)
          klass.send(:include, self::InstanceMethods)
          I18n.register_uhooks klass, InstanceMethods
        end

        module InstanceMethods
          include Standard::Page::InstanceMethods

          def uhook_publish_block_widgets(block, new_block)
            mapped_content_ids = {}
            block.widgets.each do |widget|
              next_content_id = mapped_content_ids[widget.content_id]

              new_widget = widget.clone
              new_widget.block = new_block
              new_widget.content_id = next_content_id
              new_widget.save_without_validation!

              mapped_content_ids[widget.content_id] = new_widget.content_id

              yield widget, new_widget

              new_widget.save! # must validate now
            end
          end
        end
      end

      module UbiquoDesignsHelper
        def self.included(klass)
          klass.send(:helper, Helper)
        end
        module Helper
          def uhook_link_to_edit_widget(widget)
            if widget.locale == current_locale
              link_to t('ubiquo.design.widget_edit'), ubiquo_page_design_widget_path(@page, widget), :class => "edit lightwindow", :type => "page", :params => "lightwindow_form=widget_edit_form,lightwindow_width=610", :id => "edit_widget_#{widget.id}"
            else
              link_to t('ubiquo.design.widget_translate'), ubiquo_page_design_widget_path(@page, widget), :class => "edit lightwindow", :type => "page", :params => "lightwindow_form=widget_edit_form,lightwindow_width=610", :id => "edit_widget_#{widget.id}"
            end
          end
          def uhook_load_widgets(block)
            block.widgets.locale(current_locale, :all)
          end
        end
      end

      module UbiquoWidgetsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          I18n.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          include Standard::UbiquoWidgetsController::InstanceMethods

          # modify the created widget and return it. It's executed in drag-drop.
          def uhook_prepare_widget(widget)
            widget.locale = widget.is_configurable? ? current_locale : 'any'
            widget
          end

          # Destroys a widget
          def uhook_destroy_widget(widget)
            widget.destroy_content
          end

          # updates a widget.
          # Fields can be found in params[:widget] and widget_id in params[:id]
          # must returns the updated widget
          def uhook_update_widget
            widget = ::Widget.find(params[:id])
            if current_locale != widget.locale
              widget = widget.translate(current_locale, :copy_all => true)
              widget.locale = current_locale
            end
            params[:widget].each do |field, value|
              widget.send("#{field}=", value)
            end
            widget.save
            widget
          end
        end
        module Helper
          def uhook_extra_rjs_on_update(page, valid)
            yield page
            if @widget.id
              page.replace "edit_widget_#{params[:id]}", uhook_link_to_edit_widget(@widget)
              page << "myLightWindow._processLink($('edit_widget_#{@widget.id}'));" if @widget.is_configurable?
            end
          end
        end
      end

      module UbiquoMenuItemsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          I18n.register_uhooks klass, InstanceMethods
          klass.send(:helper, Helper)
        end
        module InstanceMethods
          include Standard::UbiquoMenuItemsController::InstanceMethods

          # gets Menu items instances for the list and return it
          def uhook_find_menu_items
            ::MenuItem.locale(current_locale, :all).roots
          end

          # initialize a new instance of menu item
          def uhook_new_menu_item
            mi = ::MenuItem.translate(params[:from], current_locale)
            if mi.content_id.to_i == 0
              mi.parent_id = params[:parent_id] || 0
              mi.is_active = true
            end
            mi
          end

          def uhook_edit_menu_item(menu_item)
            unless menu_item.locale?(current_locale)
              redirect_to(ubiquo_menu_items_path)
              false
            end
          end

          #destroys a menu item instance. returns a boolean that means if destroy was done.
          def uhook_destroy_menu_item(menu_item)
            menu_item.destroy_content
          end

        end

        module Helper
          def uhook_extra_hidden_fields(form)
            form.hidden_field :content_id
          end
          def uhook_menu_item_links(menu_item)
            links = []

            if menu_item.in_locale?(current_locale)
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
          I18n.register_uhooks klass, InstanceMethods
        end

        module InstanceMethods
          def uhook_collect_widgets(b, &block)
            b.widgets.locale(current_locale).collect(&block)
          end

          def uhook_root_menu_items
            ::MenuItem.locale(current_locale).roots.active
          end

        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          include Standard::Migration::ClassMethods

          def uhook_create_widgets_table
            create_table :widgets, :translatable => true do |t|
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
