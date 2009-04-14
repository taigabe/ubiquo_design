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
      puts "Notes:
      
  - Create a component type for this generator: db/dev_bootstrap/component_types.yml
  - Create component params if needed for this component type: db/dev_bootstrap/component_params.yml
  - Remember to update the tests for the component model, the generator 
    controller and the ubiquo controller.
      "            
    end
  end

  protected
  
  def banner
    "Usage: #{$0} simple_generator name [attribute:type]"
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
