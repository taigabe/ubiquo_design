class Ubiquo::ComponentsController < UbiquoAreaController

  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
  
  helper "ubiquo/designs"
  def show
    @page = Page.find(params[:page_id])
    @component = uhook_find_component
      
    template_path = "%s/views/ubiquo/_form.html.erb" % generator_directory(@component.component_type.key)
    render :file => template_path, :locals => {:page => @page, :component => @component}
  end

  def create
    @component_type = ComponentType.find(params[:component_type])
    @block = Block.find(params[:block])
    @page = Page.find(params[:page_id])

    @component = @component_type.subclass_type.constantize.new
    @component.block = @block
    @component.component_type = @component_type
    @component.name = @component_type.name
    @component = uhook_prepare_component(@component)
    # TODO: don't do this!!
    @component.save_without_validation

    #TODO: Afegir el nou component al block de la pagina
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js {
        render :update do |page|
          page.insert_html :bottom, "block_type_holder_#{@block.block_type.id}", :partial => "ubiquo/components/component", :object => @component
          page.hide "component_#{@component.id}"
          page.visual_effect :slide_down, "component_#{@component.id}"
          id, opts = sortable_block_type_holder_options(@block.block_type.id, change_order_ubiquo_page_design_components_path(@page), @page.page_template.block_types.map(&:id))
          page.sortable id, opts
          page << "myLightWindow._processLink($('edit_component_#{@component.id}'));" if @component_type.is_configurable?
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_components", @page.wrong_components_ids
        end
      }
    end
  end

  def destroy
    @component = Component.find(params[:id])
    @page = Page.find(params[:page_id])

    uhook_destroy_component(@component)

    #TODO: Afegir el nou component al block de la pagina
    respond_to do |format|    
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.visual_effect :slide_up, "component_#{@component.id}"
          page.delay(3) do
            page.remove "component_#{@component.id}"
          end
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_components", @page.wrong_components_ids
        end
      }
    end
  end
  
  def update
    @page = Page.find(params[:page_id])
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
    @page = Page.find(params[:page_id])
    @component.name = params[:value]
    @component.save
    render :inline => @component.name
  end

  def change_order
    @page = Page.find(params[:page_id])
    params[:block].each do |block_type_id, ids|
      block_type = BlockType.find(block_type_id)
      block = @page.blocks.as_hash[block_type.key]
      Component.transaction do
        ids.each_with_index do |component_id, i|
          component = Component.find(component_id)
          component.position = i
          component.block = block
          component.save
        end
      end
    end unless params[:block].blank?
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
end
