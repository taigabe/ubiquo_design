class Ubiquo::BlockTypesController < UbiquoAreaController

  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
  
  helper "ubiquo/designs"
  def update
    use_default = params.include?(:use_default) && params[:use_default] == 'true'
    @page = Page.find(params[:page_id])
    @block_type = BlockType.find(params[:id])
    
    current = @page.blocks.as_hash[@block_type.key]
    if use_default
      current.destroy unless current.nil?
    else  
      Block.create_for_block_type_and_page(@block_type, @page) if current.nil?
    end
    @page.reload
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.remove "block_#{@block_type.id}"
          page.insert_html :after, "use_default_#{@block_type.id}", block_type_holder(@page, @block_type, :class => params[:style_class])
          
          ids = @page.page_template.block_types.map(&:id)
          @page.blocks.collect do |block|
            id, opts=sortable_block_type_holder_options(block.block_type.id, change_order_ubiquo_page_design_components_path(@page), ids)
            page.sortable(id, opts)
          end
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar', 
                                         :locals => { :page => @page.reload })
          
        end
      }
    end
  end
end
