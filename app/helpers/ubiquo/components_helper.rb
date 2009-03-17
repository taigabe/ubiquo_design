module Ubiquo::ComponentsHelper
  def component_form(page, component, &block)
    form_remote_for(
    :component, component,
    {:url => ubiquo_page_design_component_path(page, component),
      :method => :put,
      :name => "component_edit_form",
      :before => "killeditor()"
    }, &block)
  end

  def component_submit
    
    %{
      <p class="form_buttons">
        <input type="submit" class="button" value="%s" />
      </p>
    } % [t('ubiquo.design.save')]
  end
  def component_header(component)
    %{
      <h3>%s</h3>
      <a href="#" class="lightwindow_action close" rel="deactivate">%s</a>
      <div id="error_messages"></div>
    } % [(t('ubiquo.design.editing_component', :name => component.name)), t('ubiquo.design.close_component')]
  end
end
