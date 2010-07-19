class Ubiquo::BlocksController < UbiquoAreaController
  def update
    @block = Block.find(params[:id])
    @page = Page.find(params[:page_id])
    @block.update_attributes(:is_shared => params[:is_shared])

    respond_to do |format|                             
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js {
        render :update do |page|
          page.call "alert", "block shared"
        end
      }
    end
  end  
end
