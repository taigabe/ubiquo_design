require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::PagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def setup
    login_as :admin
  end

  def test_should_get_index
    get :index
    assert_response :success
    pages = assigns(:pages)
    assert_not_nil pages
    assert pages.size > 0
    pages.each do |page|
      assert_equal page.is_the_published?, false
    end
  end

  def test_shouldnt_get_index_without_permission
    login_as :eduard
    get :index
    assert_response :forbidden
  end

  def test_should_get_index_without_remove_for_keyed_pages
    get :index
    assert_select "tr#page_#{pages(:one_design).id}" do
      assert_select 'td:last-child a', :text => I18n.t('ubiquo.remove'), :count => 0
    end
    assert_select "tr#page_#{pages(:two_design).id}" do
      assert_select 'td:last-child a', :text => I18n.t('ubiquo.remove'), :count => 1
    end
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_get_new_with_possible_parent_pages
    get :new
    assert_response :success
    assert_not_equal [], assigns(:pages)
    draft_pages_without_home_page = Page.drafts - [pages(:one_design)]
    assert_equal_set draft_pages_without_home_page, assigns(:pages)
  end

  def test_should_get_new_without_possible_parent_pages
    Page.delete_all
    get :new
    assert_response :success
    assert_equal [], assigns(:pages)
  end

  def test_should_create_page_with_assigned_blocks
    assert_difference('Page.count') do
      post(:create,
           :page => {
             :name => "Custom page",
             :url_name => "custom_page",
             :page_template => "static"
           })
    end

    assert page = assigns(:page)
    assert_equal 2, page.blocks.size
    assert_equal ["top", "main"], page.blocks.map(&:block_type)
    assert_equal page.is_the_published?, false

    assert_redirected_to ubiquo_pages_path
  end

  def test_should_get_edit
    get :edit, :id => pages(:one).id
    assert_response :success
  end

  def test_should_update_page
    put(:update,
        :id => pages(:one).id,
        :page => {
          :name => "Custom page",
          :url_name => "custom_page",
          :page_template => "static"
        })
    assert_redirected_to ubiquo_pages_path
  end

  def test_should_destroy_page
    # if you remove a draft page, its published page is removed too
    assert_difference('Page.count', -2) do
      delete :destroy, :id => pages(:one_design).id
    end

    assert_redirected_to ubiquo_pages_path
  end

  def test_should_expire_page
    page = create_page(:url_name => 'one')
    Page.any_instance.expects(:expire)
    put :expire, :id => page.id
    assert_redirected_to ubiquo_pages_path
  end

  def test_should_get_expirations_page_as_admin
    login_as :admin
    UbiquoUser.any_instance.stubs(:is_superadmin?).returns(false)

    get :expirations
    assert_response :success
    assert_select "form#data-expirations-form", 1
    assert_select "input[name=expire_all]", false
  end

  def test_should_get_expirations_and_show_expire_all_button_as_superadmin
    login_as :admin
    UbiquoUser.any_instance.stubs(:is_superadmin?).returns(true)

    get :expirations
    assert_response :success
    assert_select "form#data-expirations-form", 1
    assert_select "input[name=expire_all]", true
  end

  def test_should_get_expirations_page_with_correct_permissions
    get :expirations
    assert_response :success
    assert_select "form#data-expirations-form", 1
  end

  def test_should_redirect_to_index_if_do_not_have_permissions
    without_expiration_permission do
      get :expirations
      assert_redirected_to ubiquo_pages_path
    end
  end

  def test_should_expire_all_pages_if_superadmin
    UbiquoUser.any_instance.stubs(:is_superadmin?).returns(true)

    Page.expects(:expire_all).returns(true)
    put :expire_pages, :expire_all => true
    assert_redirected_to expirations_ubiquo_pages_path
    assert_not_nil flash[:notice]
  end

  def test_should_not_expire_all_pages_if_not_superadmin
    UbiquoUser.any_instance.stubs(:is_superadmin?).returns(false)
    Page.expects(:expire_all).never
    put :expire_pages, :expire_all => true
    assert_redirected_to expirations_ubiquo_pages_path
    assert_not_nil flash[:error]
  end

  def test_should_expire_some_pages
    login_as :admin
    one = create_page(:url_name => 'one')
    two = create_page(:url_name => 'two')
    Page.expects(:expire).with([one.id.to_s, two.id.to_s]).returns([one, two])
    put :expire_pages,
        :expire_selected => true,
        :selector        => { :pages => [one.id.to_s, two.id.to_s] }
    assert_redirected_to expirations_ubiquo_pages_path
    assert_not_nil flash[:notice]
  end

  def test_should_try_to_expire_some_pages_and_show_error_message
    login_as :admin
    one = create_page(:url_name => 'one')
    Page.expects(:expire).with([one.id.to_s]).returns([])
    put :expire_pages,
        :expire_selected => true,
        :selector        => { :pages => [one.id.to_s] }
    assert_redirected_to expirations_ubiquo_pages_path
    assert_equal I18n.t("ubiquo.page.any_page_expired"), flash[:error]
  end

  def test_should_expire_url
    login_as :admin
    url = 'http://www.fcbarcelona.com'
    Page.expects(:expire_url).with(url)
    put :expire_pages,
        :expire_selected => true,
        :url             => url
    assert_redirected_to expirations_ubiquo_pages_path
    assert_not_nil flash[:notice]
  end

  def test_should_render_expire_if_superadmin
    login_as :admin
    UbiquoUser.any_instance.stubs(:is_superadmin?).returns(true)

    pages = [create_page(:url_name => 'one')]
    pages.each.map(&:publish)
    get :index
    assert_response :success
    assert_select "tr#page_#{pages.first.id}" do
      assert_select 'td:last-child a', :text => I18n.t("ubiquo.page.expire"), :count => 1
    end
  end

  def test_should_not_render_expire_if_no_permissions
    Page.any_instance.expects(:can_be_expired_by?).at_least_once.returns(false)
    pages = [create_page(:url_name => 'one')]
    pages.each.map(&:publish)
    get :index
    assert_response :success
    assert_select "tr#page_#{pages.first.id}" do
      assert_select 'td:last-child a', :text => I18n.t("ubiquo.page.expire"), :count => 0
    end
  end

  protected

  def without_expiration_permission
    original = Ubiquo::Settings[:ubiquo_design][:expiration_permit]
    Ubiquo::Settings[:ubiquo_design][:expiration_permit] = lambda do
      false
    end
    yield
    Ubiquo::Settings[:ubiquo_design][:expiration_permit] = original
  end

end
