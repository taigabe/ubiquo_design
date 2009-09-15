class Ubiquo::MenuItemsController < UbiquoAreaController
  
  ubiquo_config_call :sitemap_access_control, {:context => :ubiquo_design}
    
  before_filter :load_automatic_menus, :on => [:new, :edit] 
  
  # GET /menu_items
  # GET /menu_items.xml
  def index
    @menu_items = uhook_find_menu_items

    respond_to do |format|
      format.html {} # index.html.erb  
      format.xml  {
        render :xml => @menu_items
      }
    end
  end

  # GET /menu_items/new
  # GET /menu_items/new.xml
  def new
    @menu_item = uhook_new_menu_item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @menu_item }
    end
  end

  # GET /menu_items/1/edit
  def edit
    @menu_item = MenuItem.find(params[:id])
  end

  # POST /menu_items
  # POST /menu_items.xml
  def create
    @menu_item = uhook_create_menu_item

    respond_to do |format|
      if @menu_item.valid?
        flash[:notice] = t('ubiquo.design.sitemap_created')
        format.html { redirect_to(ubiquo_menu_items_path) }
        format.xml  { render :xml => @menu_item, :status => :created, :location => @menu_item }
      else
        flash[:error] = t('ubiquo.design.sitemap_create_error')
        format.html { render :action => "new" }
        format.xml  { render :xml => @menu_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /menu_items/1
  # PUT /menu_items/1.xml
  def update
    @menu_item = MenuItem.find(params[:id])

    respond_to do |format|
      if uhook_update_menu_item(@menu_item)
        flash[:notice] = t('ubiquo.design.sitemap_updated')
        format.html { redirect_to(ubiquo_menu_items_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.design.sitemap_update_error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @menu_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /menu_items/1
  # DELETE /menu_items/1.xml
  def destroy
    @menu_item = MenuItem.find(params[:id])
    if uhook_destroy_menu_item(@menu_item)
      flash[:notice] = t('ubiquo.design.sitemap_removed')
    else
      flash[:error] = t('ubiquo.design.sitemap_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_menu_items_path) }
      format.xml  { head :ok }
    end
  end
  
  # PUT /ubiquo/menu_items/update_positions
  #
  # Called when the menu items has been re-ordered, updates
  # immediately the records to reflect the new order  
 def update_positions
    params[params[:column]].inject(1) do |position, menu_item_id|
      MenuItem.find(menu_item_id).update_attribute(:position, position)
      position + 1
    end
    head :ok
  end
  
  private
  
  def load_automatic_menus
    @automatic_menus = uhook_load_automatic_menus
  end
end
