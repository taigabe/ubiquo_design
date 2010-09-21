class Ubiquo::BlocksController < UbiquoAreaController
  helper 'ubiquo/designs'
  def update
    @block = Block.find(params[:id])
    @page = Page.find(params[:page_id])
    @block.update_attributes(
      :is_shared => params[:is_shared],
      :shared_id => params[:shared_id])

    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js
    end
  end
end
