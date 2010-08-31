require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::WidgetCacheTest < ActiveSupport::TestCase

  def teardown
    UbiquoDesign::WidgetCache.clear(:test)
  end

  def test_should_initialize_structure
    UbiquoDesign::WidgetCache.define(:test) {}
    assert_equal({}, UbiquoDesign::WidgetCache.get(:test))
  end

  def test_should_store_model
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => Page
      }
    end
    assert_equal([Page], UbiquoDesign::WidgetCache.get(:test)[:widget][:models])
  end

  def test_should_store_self_key
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => :self
      }
    end
    assert UbiquoDesign::WidgetCache.get(:test)[:widget][:self]
  end

  def test_should_store_self_key_by_default_on_definition
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => Page
      }
    end
    assert UbiquoDesign::WidgetCache.get(:test)[:widget][:self]
  end

  def test_should_store_proc
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => lambda{'result'}
      }
    end
    assert_equal 'result', UbiquoDesign::WidgetCache.get(:test)[:widget][:procs].first.call
  end

  def test_should_store_params_as_symbols
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => :id
      }
    end
    assert_equal [:id], UbiquoDesign::WidgetCache.get(:test)[:widget][:params]
  end

  def test_should_store_array_of_elements
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => [Page, :id, Widget, :name, lambda{'result'}]
      }
    end
    assert_equal [:id, :name], UbiquoDesign::WidgetCache.get(:test)[:widget][:params]
    assert_equal [Page, Widget], UbiquoDesign::WidgetCache.get(:test)[:widget][:models]
    assert_equal 'result', UbiquoDesign::WidgetCache.get(:test)[:widget][:procs].first.call
  end

  def test_should_store_directly_a_hash
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => {
          :models => [Page, Widget],
          :params => :id,
          :procs => [lambda{'result'}],
          :self => false
        }
      }
    end
    assert_equal [:id], UbiquoDesign::WidgetCache.get(:test)[:widget][:params]
    assert_equal [Page, Widget], UbiquoDesign::WidgetCache.get(:test)[:widget][:models]
    assert_equal 'result', UbiquoDesign::WidgetCache.get(:test)[:widget][:procs].first.call
    assert !UbiquoDesign::WidgetCache.get(:test)[:widget][:self]
  end

  def test_should_clear
    UbiquoDesign::WidgetCache.define(:test) do
      {
        :widget => :id
      }
    end
    UbiquoDesign::WidgetCache.clear(:test)
    assert_equal({}, UbiquoDesign::WidgetCache.get(:test))
  end
end