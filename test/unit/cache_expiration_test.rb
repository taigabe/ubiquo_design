require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::CacheExpirationTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign.cache_manager
  end

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  test 'should_expire_widget_on_model_update' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => Page
      }
    end
    widget = widgets(:one)
    @manager.cache(widget, 'content', caching_options)
    assert @manager.get(widget, caching_options)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    page.save
    assert !@manager.get(widget, caching_options)
  end

  test 'should_expire_widget_on_model_creation' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => Widget
      }
    end
    widget = widgets(:one)
    @manager.cache(widget, 'content', caching_options)
    assert @manager.get(widget, caching_options)
    new = Free.new(:name => 'free', :block => blocks(:one), :content => 'test')
    new.instance_variable_set(:@cache_policy_context, :test)
    new.save
    assert !@manager.get(widget, caching_options)
  end

  test 'should_expire_correct_widgets_on_model_instance_update' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [Page, :id]
      }
    end
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    @manager.cache(widget, 'content', caching_options(page.id))
    @manager.cache(widget, 'content', caching_options('other'))
    assert @manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
    page.save
    assert !@manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
  end

  protected

  def create_widget
    Free.create(:name => 'free', :block => blocks(:one), :content => 'test')
  end

  def caching_options(id = 'test')
    {
      :scope => OpenStruct.new(:params => {:id => id}, :one => 'one'),
      :policy_context => :test
    }
  end

end