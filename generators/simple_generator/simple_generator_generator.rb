class SimpleGeneratorGenerator < Rails::Generator::NamedBase

  def initialize(*runtime_args)
    super(*runtime_args)
  end

  def manifest
    record do |m|
      break if @name.blank?
      m.directory('app/models/')
      m.directory(File.join('app/generators/', @name, 'views', 'ubiquo'))
      m.directory(File.join('test/functional/generators'))
      m.directory(File.join('test/functional/generators/ubiquo'))
      
      m.template('generator.rb.erb', File.join('app/generators', @name, "generator.rb"))
      m.template('views/_show.html.erb', File.join('app/generators', @name, "views", "_show.html.erb"))
      m.template('views/ubiquo/_form.html.erb', File.join('app/generators', @name, "views", "ubiquo", "_form.html.erb"))
      m.template('models/component.rb.erb', File.join('app/models', "#{@name}.rb"))

      m.template('test/unit/generator_test.rb.erb', File.join('test/unit', "#{@name}_test.rb"))
      m.template('test/functional/generator_test.rb.erb', File.join('test/functional/generators', "#{@name}_test.rb"))
      m.template('test/functional/ubiquo/generator_test.rb.erb', File.join('test/functional/generators/ubiquo', "#{@name}_test.rb"))
      m.migration_template 'migration.rb', 'db/migrate', :assigns => { 
        :migration_name => "Create#{@name.classify}Component"
      }, :migration_file_name => "create_#{@name}_component"
      puts "Notes:
      
  - Change the component type name in migration if you want
  - Remember to update the tests for the component model, the generator 
    controller and the ubiquo controller.
      "            
    end
  end

  protected
  
  def banner
    "Usage: #{$0} simple_generator name [attribute:type]"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--templates template_key, template_key2", Array,
      "Relate component with these templates") { |v| options[:templates] = v }
    opt.on("--params param_name, param_nam2", Array,
      "Creates a component param") { |v| options[:params] = v }
  end
end
