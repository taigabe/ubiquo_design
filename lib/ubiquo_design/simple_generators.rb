#= How to create a component and use on the design
#
#== Generators
#
#The _simple_generators_ (<tt>lib/simple_generators</tt>) provide infrastructure to include generators in your apps. Generators allow the reuse of components on your public website.
#
#We combine the simplicity of this generators with the design data-model (pages, page templates, blocks, components and component types) to build the website.
#
#=== How to use it 
#
#Let's see an example of a generator that displays the last news. The first step is using the _simple_generator_ generator to build the skeleton:
#
#  script/generate simple_generator last_news default_news_to_show:integer
#
#This will create the directory <tt>app/generators/last_news</tt>, the generator main file <tt>app/generators/last_news/generator.rb</tt>, the views and tests. The file <tt>generator.rb</tt> looks like this:
#
#  def last_news_generator(component, options):
#    ...
#    locals = {
#    }
#    render_options = {}
#    [locals, render_options]
#  end
#
#Render options are:
#
#* template: defines the template file to render. By default, the template file is located at <tt>app/generators/NAME/views/_show.html.erb</tt>.
#
#The local namespace is available on the generator view, by default at <tt>app/generators/last_news/views/_show.html.erb</tt>.
#
#== Creating the component type 
#
#A generator has an associated component (a model derived from _Component_) and cannot be included in our pages until we create its associated _component type_:
#
#  # db/dev_bootstrap/component_types.yml
#  news:
#    id: 1
#    name: Last news
#    key: last_news
#    is_configurable: true
#    subclass_type: LastNews
#
#Note that we set the _is_configurable_ attribute. This means that the component has some fields editable by the ubiquo user (in this case, how many news will be shown by default).
#
#Although the component type is created, we won't see it on the design page unless it's associated with a page_template:
#
#  # db/dev/bootstrap/page_template_component_types.yml
#  page_template_component_type_001:
#    page_template: simple
#    component_type: last_news
#
#== Creating the component
#
#Once the component is created, edit its associated model (<tt>app/models/last_news.rb</tt>) and use the class method _allowed_options_ to define the configurable attributes. We can also add validations over these fields:
#
#  class LastNews < Component
#    self.allowed_options = [:default_news_to_show]
#    validates_numericality_of :default_news_to_show
#    
#    def last_news(news_to_show = nil)
#      News.find(:all, :limit => news_to_show || self.default_news_to_show, 
#                      :order => 'publish_date DESC')  
#    end
#  end
#
#== Implementing the generator
#
#Edit <tt>generator.rb</tt>:
#
#  def last_news_generator(component, options):
#    ...
#    locals = {
#      :last_news => component.last_news(options[:max_news])
#    }
#    render_options = {}
#    [locals, render_options]
#  end
#
#And use the locals namespace on the view:
#
#  <% last_news.each do |news| %>
#    <p><%= news.body %></p>
#  <% end %> 
#
#As the component is configurable, we have to prepare a ubiquo view, which could look like this: 
#
#  # app/generators/last_news/views/ubiquo/_form.html.erb
#  <%= component_header component %>
#  <% component_form(page, component) do |f| %>
#      <%= f.label :default_news_to_show, t("Contents") %><br/>
#      <%= f.text_field :default_news_to_show, %>
#      <%= component_submit %>
#  <% end %>
#
#== Configuring the conponent params 
# 
#The last parameter of the generator (_options_) is a hash containing a filtered copy of the controller _params_. Only the component params associated with a given component type will be received on the component:
#
#  # db/dev_bootstrap/component_params.yml
#  component_params_001: 
#    name: max_news
#    id: "1"
#    component_type_id: "1"
#    is_required: f
#
#If the _component_param_ is declared as required, the _pages_controller' will will raise a ActiveRecord::RecordNotFound exception unless it is present on _params_.
#
#And that's it, you should now be able to insert the component on your page, configure it, publish the page and see the results on the public page.
#
#== Testing the component
#
#The skeleton created the basic infrastructure to test the component:
#
#* unit/name_test.rb: Test the associated model. 
#* functional/generators/name_test.rb: Test the generator and public views.
#* functional/generators/ubiquo/name_test.rb: Test the ubiquo views. 
#
#Check the exisiting tests for more details.
module UbiquoDesign
  module SimpleGenerators
    # Define error exceptions       
    class GeneratorError < StandardError; end    
    class GeneratorNotFound < GeneratorError; end
    class GeneratorTemplateNotFound < GeneratorError; end    
    class GeneratorResourceError < GeneratorError; end

    DEFAULT_GENERATORS_PATHS = ["#{RAILS_ROOT}/app/generators"]
    @generators_paths = DEFAULT_GENERATORS_PATHS
    
    def self.generators_paths=(paths)
      @generators_paths = paths
    end
    
    def self.generators_paths
      @generators_paths
    end
    
    # Load generators functions (seek for app/generators/*/*generator.rb files)      
    def initialize
      SimpleGenerators.generators_paths.each do |path|
        Dir[File.join(path, "*", "generator.rb")].each do |generator|
          RAILS_ENV == "development" ? load(generator) : require(generator)
        end
      end
    end
    
    def generator_directory(generator)
      SimpleGenerators.generators_paths.each do |path|
        path = File.join(path, generator.to_s)
        return path if File.directory?(path)
      end
      raise GeneratorNotFound.new("Generator not found: #{generator.to_s}")   
    end
    
    private

    # Returns an array with all available generators
    #
    # Example: available_generators.include?(:my_generator)
    def available_generators
      self.private_methods.grep(/_generator$/).collect do |generator| 
        generator.sub(/_generator/, '').to_sym
      end
    end

    # Run a generator given its name (#{name}_generator)
    def run_generator(name, *args)
      send("#{name.to_s}_generator", *args)
    end

    # Renders the generator as a string
    #
    # Example: render_generator_to_string(:test, arg1, arg2)
    # In this case, he test generator receives arg1 and arg2 as arguments.     
    def render_generator_to_string(generator, options)
      raise GeneratorNotFound.new("Generator #{generator.to_s} not found") unless available_generators.include?(generator)
      args = options.delete(:generator_args) || []
      template = options.delete(:template)
      locals, render_options = run_generator(generator, *args)
      return unless locals
      generator_to_render = (render_options[:generator] || generator).to_s
      template_to_render = (render_options[:template] || template)  
      template_file = search_template(generator_to_render, template_to_render)
      # Add template directory to view_paths, so as to render partials 
      # use this directory as defaults
      self.view_paths.unshift(File.dirname(template_file)) 
      render_output = render_to_string :file => template_file, :locals => locals
      self.view_paths.shift
      render_output
    end
    
    def search_template(generator, name)
      generator_path = generator_directory(generator)
      template_path = File.join(generator_path, "views", "_#{name}.html.erb")
      raise GeneratorTemplateNotFound.new("template file not found: #{name}") unless File.exists?(template_path)   
      template_path
    end
    
  end
end
