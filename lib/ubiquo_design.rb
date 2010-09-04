require 'ubiquo_design/extensions'
require 'ubiquo_design/ubiquo_widgets'
require 'ubiquo_design/render_page'
require 'ubiquo_design/version'
require 'ubiquo_design/cache_managers/base'

ActionController::Base.send(:include, UbiquoDesign::UbiquoWidgets)
