class PagesController < PublicController
  after_filter  :include_expiration_headers, :unless => :widget_request?

  # Renders a Page using its associated template, displaying its blocks and widgets
  def show
    @page = uhook_load_page
    render_widget_only || render_page(@page)
  end

end
