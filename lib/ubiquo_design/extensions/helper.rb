module UbiquoDesign
  module Extensions
    module Helper
      def design_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text = I18n.t("ubiquo.design.design")
          tab.title = I18n.t("ubiquo.design.design_title")
          tab.highlights_on({:controller => "ubiquo/pages"})
          tab.highlights_on({:controller => "ubiquo/page_templates"})
          tab.highlights_on({:controller => "ubiquo/designs"})
          tab.link = ubiquo_pages_path
        end if ubiquo_config_call :design_permit, {:context => :ubiquo_design}
      end

      def sitemap_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text =  I18n.t("ubiquo.design.sitemap")
          tab.title =  I18n.t("ubiquo.design.sitemap_title")
          tab.highlights_on({:controller => "ubiquo/menu_items"})
          tab.link = ubiquo_menu_items_path
        end if ubiquo_config_call :sitemap_permit, {:context => :ubiquo_design}
      end


      def render_generator_partial(name, options)
        render(options.merge(:partial => "/" + name))
      end

      def human_localized_current_date(time=nil)
        time = Time.now unless time
        time.strftime_locale("%A, %d de %B de %Y")
      end

      # Return the url for a page
      def url_for_page(page, url_for_options = {})
        page = Page.find_by_key(page.to_s) unless page.is_a?(Page)
        page_url_for_options = {
          :controller => '/pages',
          :action => 'show',
          :url => page.url_name,
        }
        url_for(page_url_for_options.merge(url_for_options))
      end

      # Create a link to a public page from a page instance
      def link_to_page(caption, page, url_for_options = {}, link_to_options = {})
        url = url_for_page(page, url_for_options)
        link_to(caption, url, link_to_options)
      end
    end
  end
end
