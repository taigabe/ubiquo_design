require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::CachePoliciesTest < ActiveSupport::TestCase

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  def test_should_initialize_structure
    UbiquoDesign::CachePolicies.define(:test) {}
    assert_equal({}, UbiquoDesign::CachePolicies.get(:test))
  end

  def test_should_store_model
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => Page
      }
    end
    assert_equal([Page], UbiquoDesign::CachePolicies.get(:test)[:widget][:models])
  end

  def test_should_store_self_key
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => :self
      }
    end
    assert UbiquoDesign::CachePolicies.get(:test)[:widget][:self]
  end

  def test_should_store_self_key_by_default_on_definition
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => Page
      }
    end
    assert UbiquoDesign::CachePolicies.get(:test)[:widget][:self]
  end

  def test_should_store_proc
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => lambda{'result'}
      }
    end
    assert_equal 'result', UbiquoDesign::CachePolicies.get(:test)[:widget][:procs].first.call
  end

  def test_should_store_params_as_symbols
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => :id
      }
    end
    assert_equal [:id], UbiquoDesign::CachePolicies.get(:test)[:widget][:params]
  end

  def test_should_store_array_of_elements
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => [Page, :id, Widget, :name, lambda{'result'}]
      }
    end
    assert_equal [:id, :name], UbiquoDesign::CachePolicies.get(:test)[:widget][:params]
    assert_equal [Page, Widget], UbiquoDesign::CachePolicies.get(:test)[:widget][:models]
    assert_equal 'result', UbiquoDesign::CachePolicies.get(:test)[:widget][:procs].first.call
  end

  def test_should_store_directly_a_hash
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => {
          :models => [Page, Widget],
          :params => :id,
          :procs => [lambda{'result'}],
          :self => false
        }
      }
    end
    assert_equal [:id], UbiquoDesign::CachePolicies.get(:test)[:widget][:params]
    assert_equal [Page, Widget], UbiquoDesign::CachePolicies.get(:test)[:widget][:models]
    assert_equal 'result', UbiquoDesign::CachePolicies.get(:test)[:widget][:procs].first.call
    assert !UbiquoDesign::CachePolicies.get(:test)[:widget][:self]
  end

  def test_should_clear
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => :id
      }
    end
    UbiquoDesign::CachePolicies.clear(:test)
    assert_equal({}, UbiquoDesign::CachePolicies.get(:test))
  end
end