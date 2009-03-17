class Ubiquo::PageCategoriesController < UbiquoAreaController

  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}

  # GET /page_categories
  # GET /page_categories.xml
  def index
    order_by = params[:order_by] || Ubiquo::Config.context(:ubiquo_design).get(:page_categories_default_order_field)
    sort_order = params[:sort_order] || Ubiquo::Config.context(:ubiquo_design).get(:page_categories_default_sort_order)
    per_page = Ubiquo::Config.context(:ubiquo_design).get(:page_categories_elements_per_page)

    @page_categories_pages, @page_categories = PageCategory.paginate(:page => params[:page], :per_page => per_page) do
      PageCategory.find :all, :order => "#{order_by} #{sort_order}"
    end
    
    respond_to do |format|
      format.html { } # index.html.erb  
      format.xml  {
        render :xml => @page_categories
      }
    end
  end

  # GET /page_categories/new
  # GET /page_categories/new.xml
  def new
    @page_category = PageCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page_category }
    end
  end

  # GET /page_categories/1/edit
  def edit
    @page_category = PageCategory.find(params[:id])
  end

  # POST /page_categories
  # POST /page_categories.xml
  def create
    @page_category = PageCategory.new(params[:page_category])

    respond_to do |format|
      if @page_category.save
        flash[:notice] = t('ubiquo.design.page_category_create')
        format.html { redirect_to(ubiquo_page_categories_path) }
        format.xml  { render :xml => @page_category, :status => :created, :location => @page_category }
      else
        flash[:error] = t('ubiquo.design.page_category_create_error')
        format.html { render :action => "new" }
        format.xml  { render :xml => @page_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /page_categories/1
  # PUT /page_categories/1.xml
  def update
    @page_category = PageCategory.find(params[:id])

    respond_to do |format|
      if @page_category.update_attributes(params[:page_category])
        flash[:notice] = t('ubiquo.design.page_category_edited')
        format.html { redirect_to(ubiquo_page_categories_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.design.page_category_edit_error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /page_categories/1
  # DELETE /page_categories/1.xml
  def destroy
    @page_category = PageCategory.find(params[:id])
    if @page_category.destroy
      flash[:notice] = t('ubiquo.design.page_category_remove')
    else
      flash[:error] = t('ubiquo.design.page_category_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_page_categories_path) }
      format.xml  { head :ok }
    end
  end
end
