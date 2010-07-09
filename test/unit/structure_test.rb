require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::StructureTest < ActiveSupport::TestCase

  def teardown
    UbiquoDesign::Structure.clear(:test)
    UbiquoDesign::Structure.clear(:other)
  end

  def test_should_initialize_structure
    UbiquoDesign::Structure.define(:test) {}
    assert_equal({}, UbiquoDesign::Structure.get(:test))
  end

  def test_should_clear
    UbiquoDesign::Structure.define(:test) do
      widget :logo
    end
    UbiquoDesign::Structure.clear(:test)
    assert_equal({}, UbiquoDesign::Structure.get(:test))
  end

  def test_should_clean_scope
    UbiquoDesign::Structure.define(:other) {}
    assert_raise ZeroDivisionError do
      UbiquoDesign::Structure.define(:test) do
        widget :logo
        1/0
      end
    end
    # TODO test
    assert_equal({}, UbiquoDesign::Structure.get(:other))
  end

  def test_should_store_structures
    UbiquoDesign::Structure.define(:test) do
      widget :logo
      page_template :pt
    end

    assert_equal(
      {:widgets => [:logo], :page_templates => [:pt]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_store_repeated_structures
    UbiquoDesign::Structure.define(:test) do
      widget :logo, :head
      widget :lemma
    end

    assert_equal(
      {:widgets => [:logo, :head, :lemma]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_store_nested_structures
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
      end
      widget :head
    end

    assert_equal({
        :page_templates => {:pt => {:widgets => [:logo, :head]}},
        :widgets => [:logo, :head]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_get_nested_structures_page_template
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
        block :block do
          widget :exclusive
        end
      end
      widget :head do
        description 'description'
        name 'name'
      end
    end

    assert_equal({
        :widgets => [:logo, :head],
        :blocks => [{:block => {:widgets => :exclusive}}]
      },
      UbiquoDesign::Structure.get(:test, {:page_template => :pt})
    )
  end

  def test_should_get_nested_structures_widgets_by_block
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
        block :block do
          widget :exclusive
        end
      end
      widget :exclusive do
        description 'description'
        name 'name'
      end
    end

    assert_equal({
        :widgets => [:logo, {:name => 'name', :description => 'description'}],
      },
      UbiquoDesign::Structure.get({:page_template => :pt, :block => :block})
    )
  end
end