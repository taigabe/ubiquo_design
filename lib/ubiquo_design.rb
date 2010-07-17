require 'ubiquo_design/extensions.rb'
require 'ubiquo_design/ubiquo_widgets.rb'
require 'ubiquo_design/render_page.rb'
require 'ubiquo_design/version.rb'

ActionController::Base.send(:include, UbiquoDesign::UbiquoWidgets)
