module UbiquoDesign
  module RenderPage
    private
    def render_page(page)
      @blocks = page.all_blocks.collect do |block|
        block_output = render_block(block)
        # Return if block is void (normally, a redirect ocurred)
        return unless block_output
        [block.block_type.key.to_sym, block_output.join]
      end.to_hash
      @menu = build_menu
      render_template_file(page.page_template.key, page.page_template.layout)
    end

    # Render all components contained on a block (calling the configured
    # generator) as string
    def render_block(block)
      block.components.collect do |component|      
        # Build a hash containing the options for this component (get info
        # from params). Copy only those keys found in component_params,
        # checking also that the required params are present.
        next unless component.valid?
        component_params = component.component_type.component_params.find(:all)
        generator_options = component_params.collect do |component_param|
          param_name = component_param.name
          if component_param.is_required? && !params[param_name.to_sym]
            component_name = component.component_type.name
            errmsg =  "Required param \"#{param_name}\" for component " \
            "\"#{component_name}\" not found. Params: #{params.inspect}"
            raise ActiveRecord::RecordNotFound.new(errmsg)
          end
          [param_name.to_sym, params[param_name]]
        end.to_hash
        generator_options.update(:request_path => request.path)
        generator = component.component_type.key.to_sym
        generator_output = render_generator_to_string(
                                                      generator,
                                                      :generator_args => [component, generator_options],
                                                      :template => 'show')
        # A generator didn't returned an string, return inmediately 
        return unless generator_output
        generator_output
      end
    end

    # Build a menu info array containing [root, children, is_current_root] elements
    # To check if a menuitem is selected, sort all the menu_items by url string
    # length and detect the first that matches the beginning of the url
    # with the request path.
    def build_menu
      menu_items = MenuItem.find(:all, :conditions => ['is_linkable = ?', true])
      current_menuitem = menu_items.sort_by { |mi| -mi.url.size }.detect do |mi|
        request.path =~ /^#{mi.url}/
      end
      MenuItem.active_roots.collect do |root|
        is_current_root = ([root] + root.children).include?(current_menuitem)
        children = if root.automatic_menu
                     locals, render_options = run_generator(root.automatic_menu.generator)
                     locals[:menu_items]
                   else                        
                     root.active_children
                   end
        [root, children, is_current_root]
      end
    end

    def template_directory
      (RAILS_ENV == 'test')? File.join(ActiveSupport::TestCase.fixture_path, "templates") : 
        "#{RAILS_ROOT}/app/templates"
    end

    def render_template_file(key, layout = 'main')
      template_file = File.join(template_directory, key, "public.html.erb")
      render :file => template_file, :layout => layout
    end
  end
end
