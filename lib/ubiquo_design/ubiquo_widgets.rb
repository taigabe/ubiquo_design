#= How to create a widget and use it on ubiquo_design
#
#== Widgets
#
#The _ubiquo_widgets_ allow the reuse of typical blocks of logic and views on your public website.
#
#We combine the simplicity of these widgets with the ubiquo_design models (pages and blocks) to build the website.
#
#=== How to use it
#
#Let's see an example of a widget that displays the last news. The first step is using the _ubiquo_widget_ widget to build the skeleton:
#
#  script/generate ubiquo_widget last_news news_to_show:integer
#
#This will create the views directory <tt>app/views/widgets/last_news</tt>, the widget main file <tt>app/widgets/last_news.rb</tt>, the associated model and all the corresponding tests. The file <tt>last_news.rb</tt> looks like this:
#
#  Widget.behaviour :last_news do |component|
#    ...
#  end
#
#This is equivalent to a piece of a controller, and all the code you put in the block will be executed in the controller space.
#
#* template: defines the template file to render. By default, the template file is located at <tt>app/widgets/NAME/views/_show.html.erb</tt>.
#
#== Creating the widget model
#
#A widget has an associated model (subclass of _Widget_), since we are always rendering an instance of a model.
#
#You can edit the associated model (<tt>app/models/last_news.rb</tt>) and use the class method _allowed_options_ to define the configurable attributes. We can also add validations over these fields:
#
#  class LastNews < Widget
#    self.allowed_options = [:news_to_show]
#    validates_numericality_of :news_to_show
#
#    def last_news(number = nil)
#      News.all(:limit => number || news_to_show, :order => :publish_date)
#    end
#  end
#
#== Implementing the widget
#
#Edit <tt>widgets/last_news.rb</tt>:
#
#  Widget.behaviour :last_news do |component|
#    @news = component.last_news(params[:max_news])
#  end
#
#And on the view:
#
#  <% @last_news.each do |news| %>
#    <p><%= news.body %></p>
#  <% end %>
#
#As the widget is configurable (to set the default :news_to_show), we can prepare an ubiquo view, which could look like this:
#
#  # app/views/widgets/last_news/ubiquo/_form.html.erb
#  <%= widget_header widget %>
#  <% widget_form(page, widget) do |f| %>
#      <%= f.label :news_to_show, Widget.human_attribute_name :news_to_show %><br/>
#      <%= f.text_field :default_news_to_show, %>
#      <%= component_submit %>
#  <% end %>
#
#== Reading from params
#
#All the params that your widget needs can be accessed from the params structure, since the widget behaviour is executed in the controller scope
#
#And that's it, you should now be able to insert the widget on your page, configure it, publish the page and see the results on the public page.
#
#== Testing the component
#
#The skeleton created the basic infrastructure to test the component:
#
#* unit/name_test.rb: Test the associated model.
#* functional/widgets/name_test.rb: Test the widget and public views.
#* functional/widgets/ubiquo/name_test.rb: Test the ubiquo views.
#
#Check the exisiting tests for more details.
module UbiquoDesign
  module UbiquoWidgets
    # Define error exceptions
    class WidgetError < StandardError; end
    class WidgetNotFound < WidgetError; end
    class WidgetTemplateNotFound < WidgetError; end

    DEFAULT_WIDGETS_PATHS = ["#{RAILS_ROOT}/app/widgets"]
    @@widgets_paths = DEFAULT_WIDGETS_PATHS

    mattr_accessor :widgets_paths

    # Load widgets functions (seek for app/widgets/*/*widget.rb files)
    def initialize
      UbiquoWidgets.widgets_paths.each do |path|
        Dir[File.join(path, "*", "widget.rb")].each do |widget|
          Rails.env.development? ? load(widget) : require(widget)
        end
      end
    end

    private

    # Returns an array with all the available widgets
    #
    # Example: available_widgets.include?(:my_widgets)
    def available_widgets
      ::Widget.behaviours.keys
    end

    # Run a widget given its name
    def run_behaviour(name, *args)
      send("#{name.to_s}_widget", *args)
    end

    # Renders the widget as a string
    #
    # Example: render_widget_to_string(:test, arg1, arg2)
    # In this case, he test widget receives arg1 and arg2 as arguments.
    def render widget
      raise WidgetNotFound.new("Widget #{widget.to_s} not found") unless available_widgets.include?(widget)
      run_behaviour(widget)
      template_file = search_template(widget, template_to_render)
      # Add template directory to view_paths, so as to render uses this directory by default
      self.view_paths.unshift(File.dirname(template_file))
      render_output = render_to_string :file => template_file
      self.view_paths.shift
      render_output
    end

    def search_template(widget)
      returning(File.join("views", "widgets", widget, "show.html.erb")) do |template_path|
        raise WidgetTemplateNotFound.new("Template file not found: #{widget}") unless File.exists?(template_path)
      end
    end

  end
end
