module UbiquoDesign::Concerns::Controllers::PagesController
  extend ActiveSupport::Concern

  included do
    after_filter  :include_expiration_headers, :unless => :widget_request?
  end

  module ClassMethods
  end

  # Renders a Page using its associated template, displaying its blocks and widgets
  def show
    @page = uhook_load_page
    render_widget_only || render_page(@page)
  end
end
