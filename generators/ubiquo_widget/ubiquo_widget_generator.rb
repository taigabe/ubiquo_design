class UbiquoWidgetGenerator < Rails::Generator::NamedBase

  def initialize(*runtime_args)
    super(*runtime_args)
  end

  def manifest
    record do |m|
      break if @name.blank?
      m.directory('app/models/widgets')
      m.directory(File.join('app/widgets'))
      m.directory(File.join('app/views/widgets/', @name, 'views', 'ubiquo'))
      m.directory(File.join('test/unit/widgets'))
      m.directory(File.join('test/functional/widgets'))
      m.directory(File.join('test/functional/widgets/ubiquo'))
      
      m.template('widget.rb.erb', File.join('app/widgets', "#{@name}_widget.rb"))
      m.template('views/_show.html.erb', File.join('app/views/widgets', @name, "_show.html.erb"))
      m.template('views/ubiquo/_form.html.erb', File.join('app/views/widgets', @name, "views", "ubiquo", "_form.html.erb"))
      m.template('models/component.rb.erb', File.join('app/models/widgets', "#{@name}.rb"))

      m.template('test/unit/widget_test.rb.erb', File.join('test/unit/widgets', "#{@name}_test.rb"))
      m.template('test/functional/widget_test.rb.erb', File.join('test/functional/widgets', "#{@name}_test.rb"))
      m.template('test/functional/ubiquo/widget_test.rb.erb', File.join('test/functional/widgets/ubiquo', "#{@name}_test.rb"))
      m.migration_template 'migration.rb', 'db/migrate', :assigns => { 
        :migration_name => "Create#{@name.classify}Widget"
      }, :migration_file_name => "create_#{@name}_widget"
      puts "Notes:
      
  - Change the widget name in migration if you want to
  - Remember to update the tests for the widget model, the widget
    controller and the ubiquo controller.
      "
    end
  end

  protected
  
  def banner
    "Usage: #{$0} ubiquo_widget example_widget [attribute:type]"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--templates template_key, template_key2", Array,
      "Relate widget with these templates") { |v| options[:templates] = v }
    opt.on("--params param_name, param_nam2", Array,
      "Creates a widget param") { |v| options[:params] = v }
  end
end
