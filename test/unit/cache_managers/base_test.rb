require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::BaseTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def setup
    @manager = UbiquoDesign.cache_manager
  end

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  test 'should cache a widget and get it back' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => :self
      }
    end
    widget_id = widgets(:one).id
    @manager.cache(widget_id, 'content', {:policy_context => :test})
    assert_equal 'content', @manager.get(widget_id, :policy_context => :test)
  end

  test 'should expire a widget cache' do
    widget_id = widgets(:one).id
    @manager.cache(widget_id, 'content')
    @manager.expire(widget_id)
    assert !@manager.get(widget_id)
  end

  test 'calculate_key for a simple widget' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => :self
      }
    end
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :policy_context => :test
      }
    )
    assert_equal widget.id.to_s, key
  end

  test 'calculate_key for a widget with params' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [:id, :name]
      }
    end
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {:id => 10, :name => 'test'}),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_params_##id##10##name##test", key
  end

  test 'calculate_key for a widget with procs' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [lambda{ one }, lambda{ two }]
      }
    end
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => OpenStruct.new(:one => 'one', :two => 'two', :params => []),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_procs_##one##two", key
  end

  test 'calculate_key for a widget with params and procs' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [lambda{ one }, :id]
      }
    end
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {:id => 'test'}, :one => 'one'),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_params_##id##test_procs_##one", key
  end

  test 'should accept a widget instead of the id' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => :self
      }
    end
    widget = widgets(:one)
    Widget.expects(:find).never
    @manager.cache(widget, 'free', {:policy_context => :test})
    assert_equal 'free', @manager.get(widget, {:policy_context => :test})
  end

  test 'should not get anything from a non cacheable widget' do
    widget = widgets(:one)
    @manager.cache(widget, 'free', {:policy_context => :test})
    assert_equal nil, @manager.get(widget)
  end
  
  test 'calculate_key for widget with param mappings' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => ['Page', {:slug => :id}]
      }
    end
    page = pages(:one)
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {:slug => page.id}, :one => 'one'),
        :policy_context => :test
      }
      )

    assert_equal "#{widget.id}_params_##slug###{page.id}", key
    key2 = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => page,
        :policy_context => :test
      }
      )
    assert_equal key, key2
  end

  test 'calculate_key for widget with proc mappings' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => ['Page', {:identifier => [lambda{|a| one}, :id]}]
      }
    end
    page = pages(:one)
    widget = create_widget
    key = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {}, :one => page.id),
        :policy_context => :test
      }
      )
    assert_equal "#{widget.id}_procs_###{page.id}", key
    key2 = @manager.send(
      :calculate_key,
      widget.id,
      {
        :scope => page,
        :policy_context => :test
      }
      )
    assert_equal key, key2
  end

  protected

  def create_widget
    Free.create(:name => 'free', :block => blocks(:one), :content => 'test')
  end


end
