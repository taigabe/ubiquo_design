map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :pages do |pages|
    pages.resource :design, :member => {:preview => :get, :publish => :put} do |design|
      design.resources :components, :collection => {:change_order => :any}, :member => {:change_name => :post}
      design.resources :block_types
    end
  end
  ubiquo.resources :page_categories

  ubiquo.resources :menu_items, :collection => {:update_positions => :put}
end
  
# Proposal for public routes. 

map.with_options :controller => 'pages' do |pages|
  # Frontpage
  pages.connect "", :action => 'show', :category => '', :url_name => ''

  # Example of page_type usage  
  # pages.connect "deep/path/:category/:url_name", :action => 'show', 
  #                                                :page_type => 'deep', 
  #                                                :defaults => {:url_name => ''}    
  
  # Common routes (modify to fit your needs)
  pages.connect ":category/:url_name", :action => 'show', :defaults => {:url_name => ''}
  pages.connect ":category/:url_name/page/:page", :action => 'show'
  pages.connect ":category/:url_name/:id", :action => 'show'
  
end
