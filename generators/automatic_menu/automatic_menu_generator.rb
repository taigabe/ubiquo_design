#= Sitemap and Menus
#
#The sitemap is simple way to organize the web and display a menu.  
#
#== Menu 
#Render the _menu_ partial in the public layout:
#
#  <div id="menu">
#    <%= render :partial => 'shared/menu', :object => @menu %>
#  </div>
#
#Note that the _@menu_ instance attribute is already set by _pages_controller_.
#
#== Automatic menus
#
#Sometimes you need that the menu show dynamic contents. In this case, you have set a _Menu Generator_ option in Ubiquo and create the corresponding generator. Let's see an example:
#
#* Automatic menu fixtures: Edit <tt>db/dev_bootstrap/automatic_menu.yml</tt> and add the automatic menu selecting a proper generator name.
#  news_automatic_menu:
#    name: "News"
#    generator: "news_menu"
# 
#* Menu Item: Select this automatic menu (_News_) on the menu item form.
# 
#* Generator: Create a generator at <tt>app/generators/name/generator.rb</tt>:
#
#  def news_menu_generator(options = {})
#    page = Page.find_by_category_and_page_name("news", "interior")
#    menu_items = News.find(:all).collect do |n|    
#      MenuItem.new(:caption => n.name,
#                   :url => url_for_public_page(page, :id => n.id),
#                   :is_linkable => true)
#    end
#    locals = {
#      :menu_items => menu_items,
#    }
#    render_options = {}
#    [locals, render_options]
#  end
#
#Note that this special generator has no associated components and it returns an array of _MenuItem_ instances on locals.
class AutomaticMenuGenerator < Rails::Generator::NamedBase

  def initialize(*runtime_args)
    super(*runtime_args)
  end

  def manifest
    record do |m|
      break if @name.blank?
      m.directory(File.join('app/generators/', @name))
      m.directory(File.join('test/functional/generators'))
      
      m.template('generator.rb.erb', File.join('app/generators', @name, "generator.rb"))
      source_generator = File.join('test/functional/generators', "#{@name}_test.rb")
      m.template('generator_test.rb.erb', source_generator)
      puts "Notes:
      
  - Create a fixture for the automatic menu: db/dev_bootstrap/automatic_menu.yml 
  - Return MenuItem records on locals[:menu_items] on generator code: #{source_generator} 
      "
    end
  end

  protected
  
  def banner
    "Usage: #{$0} automatic_menu name [attribute:type]"
  end

  #def add_options!(opt)
  #  opt.separator ''
  #  opt.separator 'Options:'
  #  opt.on("--skip-timestamps",
  #         "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
  #  opt.on("--skip-migration",
  #         "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
  #end
end
