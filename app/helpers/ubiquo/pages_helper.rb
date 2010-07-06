module Ubiquo::PagesHelper

  def pages_filters_info(params)
    string_filter = if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
                      filter_info(:string, params,
                                  :field => :filter_text,
                                  :caption => t('ubiquo.design.name'))
                    else
                      nil
                    end
    build_filter_info(string_filter)
  end

  def pages_filters(url_for_options = {})
    string_filter = if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
                      render_filter(:string, url_for_options,
                                    :field => :filter_text,
                                    :caption => t('ubiquo.design.name'))
                    else
                      ""
                    end
    string_filter
  end

  def page_url(page)
    method_route = Ubiquo::Config.get(:app_name) + "_host"
    host = self.send(method_route) if self.respond_to?(method_route)
    self.send("#{page.page_type.key}_url", {:page_name => page.url_name, :host => host})
  end

  def parent_pages_for_select(pages)
    options = ["<option value=''>#{t('ubiquo_design.no_parent')}</option>"]
    pages.map do |page|
      options << "<option value='#{page.id}' title='#{page.url_name}'>#{page.name}</option>"
    end
    options.join("\n")
  end
  
end
