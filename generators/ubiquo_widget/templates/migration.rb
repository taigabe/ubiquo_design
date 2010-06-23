class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    widget = Widget.create(:name => "<%= class_name %>",
                              :key => "<%= name %>",
                              :is_configurable => <%= attributes.present? %>,
                              :subclass_type => "<%= class_name %>")
    
    # relate component type with page templates
    <%- if options[:templates].present? -%>
    page_templates = PageTemplate.find_all_by_key(<%= options[:templates].inspect %>)
    <%- else -%>
    page_templates = PageTemplate.all
    <%- end -%>
    page_templates.each do |pt|
      pt.widgets << widget
    end    
    <%- if options[:params].present? -%>

    # create related widget params
    <%- options[:params].each do |params_name| -%>
      # TODO create it now that is not a model
    <%- end -%>
    <%- end -%>
  end
  
  def self.down
    widget = Widget.find_by_key("<%= name %>")
    PageTemplateWidget.destroy_all(:widget_id => widget.id)
    # TODO destroy widget params
    widget.destroy
  end
end
