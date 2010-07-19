class Ubiquo::ComponentsController < UbiquoAreaController
  before_filter :load_page
  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
  
  helper "ubiquo/designs"
  def show
    @component = uhook_find_component
      
    template_path = "%s/views/ubiquo/_form.html.erb" % generator_directory(@component.widget.key)
    render :file => template_path, :locals => {:page => @page, :component => @component}
  end

  def create
    @widget = Widget.find(params[:widget])
    @block = Block.find(params[:block])

    @component = @widget.subclass_type.constantize.new
    @component.block = @block
    @component.widget = @widget
    @component.name = @widget.name
    @component = uhook_prepare_component(@component)
    # TODO: don't do this!!
    @component.save_without_validation

    #TODO: Afegir el nou component al block de la pagina
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js {
        render :update do |page|
          page.insert_html :bottom, "block_type_holder_#{@block.block_type}", :partial => "ubiquo/components/component", :object => @component
          page.hide "widget_#{@component.id}"
          page.visual_effect :slide_down, "widget_#{@component.id}"
          id, opts = sortable_block_type_holder_options(@block.block_type,
                                                        change_order_ubiquo_page_design_components_path(@page),
                                                        [1,2])
          page.sortable id, opts
          page << "myLightWindow._processLink($('edit_component_#{@component.id}'));" if @widget.is_configurable?
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_components", @page.wrong_components_ids
        end
      }
    end
  end

  def destroy
    @component = Component.find(params[:id])

    uhook_destroy_component(@component)

    #TODO: Afegir el nou component al block de la pagina
    respond_to do |format|    
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.visual_effect :slide_up, "widget_#{@component.id}"
          page.delay(1) do
            page.remove "widget_#{@component.id}"
          end
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_components", @page.wrong_components_ids
        end
      }
    end
  end
  
  def update
    @component = uhook_update_component
    if @component.valid?
      respond_to do |format|
        format.html { redirect_to(ubiquo_page_design_path(@page))}
        format.js {
          render :update do |page|
            self.uhook_extra_rjs_on_update(page, true) do |page|
              page << 'myLightWindow.deactivate();'
              page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                :locals => { :page => @page.reload })
              page.call "update_error_on_components", @page.wrong_components_ids
            end
           end
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to(ubiquo_page_design_component_path(@page, @component))}
        format.js {
          render :update do |page|
            self.uhook_extra_rjs_on_update(page, false) do |page|
              page.replace_html('error_messages', :partial => 'ubiquo/designs/error_messages',
                :locals => {:component => @component})
              page << "reviveEditor();"
            end
          end
        }
      end
    end
  end

  def change_name
    @component = Component.find(params[:id])
    @component.update_attributes(:name => params[:value])
    render :inline => @component.name
  end

  def change_order
    unless params[:block].blank?
      params[:block].each do |block_type, widget_ids|
        block = @page.blocks.first(:conditions => { :block_type => block_type })
        Component.transaction do
          widget_ids.each_with_index do |widget_id, index|
            component = Component.find(widget_id)
            component.update_attributes(:position => index, :block_id => block.id)
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })     
          page.call "update_error_on_components", @page.wrong_components_ids   
        end
      }
    end
  end

  private

  def load_page
    @page = Page.find(params[:page_id])
  end
end
