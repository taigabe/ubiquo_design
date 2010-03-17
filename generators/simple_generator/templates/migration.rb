class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    ct = ComponentType.create(:name => "<%= class_name %>",
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
      pt.component_types << ct
    end    
    <%- if options[:params].present? -%>

    # create related component params
    <%- options[:params].each do |params_name| -%>
    ComponentParam.create(:name => "<%= params_name %>",
                          :is_required => <%= params_name == 'id' %>,
                          :component_type_id => ct.id)
    <%- end -%>
    <%- end -%>
  end
  
  def self.down
    ct = ComponentType.find_by_key("<%= name %>")
    PageTemplateComponentType.destroy_all(:component_type_id => ct.id)
    ComponentParam.destroy_all(:component_type_id => ct.id)
    ct.destroy
  end
end
