#= Pages design
#
#Pages created with the design module have the following attributes:
#
#* name: Descriptive name
#* url_name: String that appears on the route
#* page_template: Associated page templates (configure them on <tt>db/dev_bootstrap/page_template.yml</tt>).
#* page_type: This attribute is used to create arbitrary routes. See the example on _Public routes_ secion. 
#* page_category: Category to which the page belongs. The page categories can be created from the corresponding tab.
#* is_public: Show if a page will be shown on the public website (true) or Ubuquo (false) 
#
#By default, pages are created non public. When a page is published, it is cloned (along with its components, blocks and asset_relations) and the is_public attribute is set. In that moment the changes are visible on the public website.
#
#== Public routes
#
#Create anonymous routes from the _pages_ controller on <tt>config/routes.db</tt>:
#
#  ActionController::Routing::Routes.draw do |map|
#    ...
#    map.with_options :controller => 'pages' do |pages|
#      # Frontpage
#      pages.connect "", :action => 'show', :category => '', :url_name => ''
#      
#      # Common routes      
#      pages.connect ":category/:url_name", :action => 'show', :defaults => {:url_name => ''}
#      pages.connect ":category/:url_name/:id", :action => 'show'
#      pages.connect ":category/:url_name/page/:page", :action => 'show'
#      
#      # Example of page_type usage  
#      pages.connect "this/is/a/deep/path/:category/:url_name", :action => 'show', :page_type => 'deep', :defaults => {:url_name => ''}    
#    end
#  end
#
#The frontpage is a page with a empty string as url_name and a page_category also with empty string. 
#
#== Build links on views from pages  
#
#To create a link to public pages:
#
#  link_to_page("Public page", page)
#
#If you only need the url for a public page:
#
#  url_for_page(page)
#
#== Build links on views from page names  
#
#Sometimes you don't a have a page object, but its name (and of course, the category name). For example, to go to category _news_, page _interior_:
#
#  page = Page.find_public("news", "interior")
#  link_to_page("News interior page", page, :id => news.id)
#

class PagesController < ApplicationController
  layout 'main'
  include UbiquoDesign::RenderPage
  # Show a designed page usint its template and associated blocks and components
  # 
  # A page is formed of many blocks, each with containing components. Each
  # component use a generator to get the final HTML code
  def show
    page = uhook_load_page
    render_page page
  end
  
end
