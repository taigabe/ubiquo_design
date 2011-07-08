class PagesController < PublicController

  # Renders a Page using its associated template, displaying its blocks and widgets
  def show
    expires_in 120.seconds, :public => true
    response.headers['X-VARNISH-TTL'] = '120'
    @page = uhook_load_page
    render_page @page
  end

end
