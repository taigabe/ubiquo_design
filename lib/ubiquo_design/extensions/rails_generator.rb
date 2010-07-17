require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

module UbiquoDesign
  module Extensions
    module RailsGenerator
      module Create
        # Modify design_structure.rb and include the new widget
        def ubiquo_widget(name)
          sentinel = "  widget"
          logger.widget "#{name}"
          unless options[:pretend]
            gsub_file 'config/initializers/design_structure.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
              "#{match} :#{name},"
            end
          end
        end
      end
      module Destroy
        # Modify design_structure.rb deleting the widget
        def ubiquo_widget(name)
          logger.widget "#{name}"
          gsub_file 'config/initializers/design_structure.rb', /(widget\s+:#{name},\s+)/mi, 'widget '
        end
      end
    end
  end
end
