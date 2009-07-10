require 'ubiquo_design'


Ubiquo::Plugin.register(:ubiquo_design, directory, config) do |config|
  
  config.add :page_categories_elements_per_page
  config.add_inheritance :page_categories_elements_per_page, :elements_per_page
  
  config.add :pages_elements_per_page
  config.add_inheritance :pages_elements_per_page, :elements_per_page

  config.add :design_access_control, lambda{
    access_control :DEFAULT => "design_management"
  }
  config.add :sitemap_access_control, lambda{
    access_control :DEFAULT => "sitemap_management"
  }
  config.add :design_permit, lambda{
    permit?("design_management")
  }
  config.add :sitemap_permit, lambda{
    permit?("sitemap_management")
  }
  
  config.add :page_string_filter_enabled, true
     
  config.add :page_categories_default_order_field, 'page_categories.id'
  config.add :page_categories_default_sort_order, 'desc'
  config.add :pages_default_order_field, 'pages.url_name'
  config.add :pages_default_sort_order, 'ASC'
  
  #config.add :test, 5
end

groups = Ubiquo::Config.get :model_groups
Ubiquo::Config.set :model_groups, groups.merge(
  :ubiquo_design => %w{assets asset_relations automatic_menus block_types blocks
          component_params component_types components menu_items page_categories 
          page_template_block_types page_template_component_types page_templates
          page_types pages})

