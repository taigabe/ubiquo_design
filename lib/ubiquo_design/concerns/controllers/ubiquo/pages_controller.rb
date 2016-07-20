module UbiquoDesign::Concerns::Controllers::Ubiquo::PagesController
  extend ActiveSupport::Concern

  included do
    ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
    access_control [:destroy] => 'remove_pages'
    before_filter :load_page_templates
    before_filter :load_page, :only => [:edit, :update, :destroy]
    before_filter :load_parent_pages, :only => [:new, :edit]
  end

  module ClassMethods
  end

  # GET /pages
  # GET /pages.xml
  def index
    order_by = params[:order_by] || Ubiquo::Settings.context(:ubiquo_design).get(:pages_default_order_field)
    sort_order = params[:sort_order] || Ubiquo::Settings.context(:ubiquo_design).get(:pages_default_sort_order)

    filters = { :text => params[:filter_text] }
    per_page = Ubiquo::Settings.context(:ubiquo_design).get(:pages_elements_per_page)

    @pages_pages, @pages = Page.paginate(:page => params[:page], :per_page => per_page) do
      uhook_find_private_pages(filters, order_by, sort_order)
    end

    respond_to do |format|
      format.html {} # index.html.erb
      format.xml  {
        render :xml => @pages
      }
      format.js {
        render :json => @pages.to_json(:only => [:id, :name])
      }
    end
  end

  # GET /pages/new
  # GET /pages/new.xml
  def new
    @page = uhook_new_page

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/1/edit
  def edit
  end

  # POST /pages
  # POST /pages.xml
  def create
    @page = uhook_create_page
    respond_to do |format|
      if @page.valid?
        flash[:notice] = t('ubiquo.design.page_created')
        format.html { redirect_to(ubiquo_pages_path) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        flash[:error] = t('ubiquo.design.page_create_error')
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    respond_to do |format|
      if uhook_update_page(@page)
        flash[:notice] = t('ubiquo.design.page_edited')
        format.html { redirect_to(ubiquo_pages_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.design.page_edit_error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    if uhook_destroy_page(@page)
      flash[:notice] = t('ubiquo.design.page_removed')
    else
      flash[:error] = t('ubiquo.design.page_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_pages_path) }
      format.xml  { head :ok }
    end
  end

  # GET /pages/expirations
  def expirations
    respond_to do |format|
      format.html do
        if ubiquo_config_call :expiration_permit, {:context => :ubiquo_design}
          render :action => 'expirations'
        else
          redirect_to ubiquo_pages_path
        end
      end
    end
  end

  def expire_pages
    if params[:expire_all]
      if current_ubiquo_user.is_superadmin?
        Page.expire_all
        flash[:notice] = t("ubiquo.page.pages_all_expired")
      else
        flash[:error] = t("ubiquo.page.any_page_expired")
      end
    elsif params[:expire_selected]
      # selected pages
      ids = params[:selector][:pages] if params[:selector]
      ids ||= Array.new
      # url
      url = params[:url]

      # expiration of selected pages
      expired_pages = Page.expire(ids)
      page_names = expired_pages.map do |p|
        @template.render(:partial => 'expired_page_name', :locals => { :name => p.name })
      end

      # expiration of url
      if url.present?
        Page.expire_url(url)
        page_names << @template.render(:partial => 'expired_page_name',
                                       :locals  => { :name => url })
      end

      if page_names.present?
        flash[:notice] = t("ubiquo.page.pages_expired",
                           :num_pages  => page_names.length,
                           :page_names => page_names)
      else
        flash[:error] = t("ubiquo.page.any_page_expired")
      end
    end

    respond_to do |format|
      format.html { redirect_to expirations_ubiquo_pages_path }
    end
  end

  def expire
    page = Page.find(params[:id])
    if page.expire
      flash[:notice] = t("ubiquo.page.pages_expired", :num_pages => 1, :page_names => page.name)
    else
      flash[:error] = t("ubiquo.page.any_page_expired")
    end
    redirect_to ubiquo_pages_path
  end

  private

  def load_page_templates
    @page_templates = Page.templates
  end

  def load_page
    @page = Page.find(params[:id])
  end

  def load_parent_pages
    @pages = Page.drafts.all(:conditions => ["url_name != ''"]) - [@page]
  end

  def uhook_find_private_pages(filters, order_by, sort_order)
    ::Page.drafts.filtered_search(filters, :order => order_by + " " + sort_order)
  end

  # initializes a new instance of page.
  def uhook_new_page
    ::Page.new
  end

  # create a new instance of page.
  def uhook_create_page
    p = ::Page.new(params[:page])
    p.save
    p
  end

  #updates a page instance. returns a boolean that means if update was done.
  def uhook_update_page(page)
    page.update_attributes(params[:page])
  end

  #destroys a page isntance. returns a boolean that means if the destroy was done.
  def uhook_destroy_page(page)
    page.destroy
  end

end
