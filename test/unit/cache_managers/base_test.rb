require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::BaseTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign.cache_manager
  end

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  test 'should cache a widget and get it back' do
    widget_id = widgets(:one).id
    @manager.cache(widget_id, 'content')
    assert_equal 'content', @manager.get(widget_id)
  end

  test 'should expire a widget cache' do
    widget_id = widgets(:one).id
    @manager.cache(widget_id, 'content')
    @manager.expire(widget_id)
    assert !@manager.get(widget_id)
  end

  test 'calculate_content_id for a simple widget' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => :self
      }
    end
    widget = create_widget
    assert_equal widget.id.to_s, @manager.send(:calculate_content_id, widget.id)
  end

  test 'calculate_content_id for a widget with params' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [:id, :name]
      }
    end
    widget = create_widget
    content_id = @manager.send(
      :calculate_content_id,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {:id => 10, :name => 'test'}),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_params_##id##10##name##test", content_id
  end

  test 'calculate_content_id for a widget with procs' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [lambda{ one }, lambda{ two }]
      }
    end
    widget = create_widget
    content_id = @manager.send(
      :calculate_content_id,
      widget.id,
      {
        :scope => OpenStruct.new(:one => 'one', :two => 'two'),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_procs_##one##two", content_id
  end

  test 'calculate_content_id for a widget with params and procs' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [lambda{ one }, :id]
      }
    end
    widget = create_widget
    content_id = @manager.send(
      :calculate_content_id,
      widget.id,
      {
        :scope => OpenStruct.new(:params => {:id => 'test'}, :one => 'one'),
        :policy_context => :test
      }
    )
    assert_equal "#{widget.id}_params_##id##test_procs_##one", content_id
  end

  test 'should accept a widget instead of the id' do
    widget = widgets(:one)
    Widget.expects(:find).never
    @manager.cache(widget, 'free')
    assert_equal 'free', @manager.get(widget)
  end


  protected

  def create_widget
    Free.create(:name => 'free', :block => blocks(:one), :content => 'test')
  end


end
