module UbiquoDesign
  module RenderPage
    private
    def render_page(page)
      @menu = build_menu
      @blocks = page.blocks.collect do |block|
        block_output = render_block(block)
        # Return if block is void (normally, a redirect ocurred)
        return unless block_output
        [block.block_type.to_sym, block_output.join]
      end.to_hash
      render_template_file(page.page_template, page.layout)
    end

    # Renders all the widgets contained in a block
    def render_block(block)
      uhook_collect_widgets(block) do |widget|
        next unless widget.valid?
        widget_name = widget.key.to_sym
        returning(render(widget_name)) do |output|
          # A widget didn't return an string, return inmediately
          return unless output
        end
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
      uhook_root_menu_items.collect do |root|
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
