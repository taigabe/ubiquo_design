module Ubiquo::StaticPagesHelper
  def static_pages_filters_info(params)
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      string_filter = filter_info(:string, params,
                                  :field => :filter_text,
                                  :caption => t('ubiquo.design.name'))
    else
      string_filter = nil
    end
    build_filter_info(string_filter)
  end

  def static_pages_filters(url_for_options = {})
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      render_filter(:string, url_for_options,
                    :field => :filter_text,
                    :caption => t('ubiquo.design.name'))
    else
      ""
    end
  end

  def static_pages_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard",
           :locals => {
             :name => 'page',
             :headers => [:name, :url_name, :publish_status],
             :rows => collection.collect do |static_page| 
               {
                 :id => static_page.id,
                 :columns => [
                   (if static_page.published? && static_page.published.is_linkable?
                     link_to_page(static_page.name, static_page, {}, :popup => true)
                    else
                      static_page.name    
                    end),
                   static_page.url_name,
                   publish_status(static_page),
                 ],
                 :actions => uhook_static_page_actions(static_page)
               }
             end,
             :pages => pages,
             :link_to_new => link_to(t("ubiquo.design.static_pages.new"),
                                     new_ubiquo_static_page_path, :class => 'new')})
  end

  def publish_status(page)
    status,icon_name = if page.published? && !page.is_modified?
      ['published', 'ok']
    elsif page.published? && page.is_modified?
      ['pending_publish', 'pending']
    else
      ['unpublished', 'ko']
    end
    ubiquo_image_tag("#{icon_name}.gif",
                     :alt => t("ubiquo.design.status.#{status}"),
                     :title => t("ubiquo.design.status.#{status}")) + " " +
      t("ubiquo.design.status.#{status}")
  end

end
