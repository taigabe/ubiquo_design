module Ubiquo::PagesHelper

  def pages_filters_info(params)
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      string_filter = filter_info(:string, params,
                                  :field => :filter_text,
                                  :caption => t('ubiquo.design.name'))
    else
      string_filter = nil
    end
    build_filter_info(string_filter)
  end

  def pages_filters(url_for_options = {})
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      render_filter(:string, url_for_options,
                    :field => :filter_text,
                    :caption => t('ubiquo.design.name'))
    else
      ""
    end
  end

  def pages_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard",
      :locals => {
        :name => 'page',
        :headers => [:name, :url_name, :publish_status],
        :rows => collection.collect do |page| 
          {
            :id => page.id,
            :columns => [
              (if page.published? && page.published.is_linkable?
                 link_to_page(page.name, page, {}, :popup => true)
               else
                 page.name    
               end),
              page.url_name,
              publish_status(page),
            ],
            :actions => uhook_page_actions(page)
          }
        end,
        :pages => pages,
        :link_to_new => link_to(t("ubiquo.design.new_page"),
          new_ubiquo_page_path, :class => 'new')})
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
