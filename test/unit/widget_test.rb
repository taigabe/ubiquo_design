require File.dirname(__FILE__) + "/../test_helper.rb"

class WidgetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_widget
    assert_difference "Widget.count" do
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Widget.count" do
      widget = create_widget :name => ""
      assert widget.errors.on(:name)
    end
  end

  def test_should_require_block
    assert_no_difference "Widget.count" do
      widget = create_widget :block_id => nil
      assert widget.errors.on(:block)
    end
  end

  def test_should_auto_increment_position
    assert_difference "Widget.count", 2 do
      widget = create_widget :position => nil
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert_not_equal widget.position, nil
      position = widget.position
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert_equal widget.position, position+1
    end
  end

  def test_should_create_options_for_children
    assert_difference "Widget.count",2 do
      #CREATION
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert widget.respond_to?(:title)
      assert widget.respond_to?(:description)

      #CREATION WITH OPTIONS
      widget = create_widget :title => "title", :description => "desc"
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert widget.title === "title"
      assert widget.description === "desc"

      #FINDING
      widget = Widget.find(widget.id)
      assert widget.title === "title"
      assert widget.description === "desc"

      #MODIFY
      widget.title = "new title"
      assert widget.save
      assert Widget.find(widget.id).title === "new title"
    end
  end

  def test_should_set_is_modified_attribute_for_page_on_widget_update
    widget = widgets(:three)
    page = widget.block.page
    assert !page.reload.is_modified?
    assert widget.save
    assert page.reload.is_modified?
  end

  def test_should_set_is_modified_attribute_for_page_on_widget_delete
    widget = widgets(:three)
    page = widget.block.page
    assert !page.reload.is_modified?
    assert widget.destroy
    assert page.reload.is_modified?
  end

  def test_should_get_widget_key
    assert_equal :test_widget, TestWidget.new.key
  end

  def test_should_get_widget_class
    assert_equal TestWidget, Widget.class_by_key(:test_widget)
  end

  def test_should_return_widget_groups
    UbiquoDesign::Structure.define do
      widget_group :one do
        widget :one, :two
      end
      widget_group :two, :option => 'value' do
        widget :three, :four
      end
      widget :aa
    end
    assert_equal [:one, :two], Widget.groups[:one]
    assert_equal [:three, :four], Widget.groups[:two]
  end

  def test_delegated_page_method
    widget = create_widget
    assert_equal widget.block.page, widget.page
  end

  def test_validations_on_options_should_work
    assert_difference "Widget.count" do
      widget = create_widget_with_validations(:number => 0)
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
    end
    widget = create_widget_with_validations
    assert widget.errors.on(:number)
  end


  def test_should_exclude_by_default_asset_relations_from_clonation
    assert_equal [:asset_relations], Widget.clonation_exceptions
  end

  def test_should_exclude_a_relation_when_required
    TestWidget.expects(:write_inheritable_attribute).with(:clonation_exceptions, [:asset_relations, :my_relation])
    TestWidget.clonation_exception(:my_relation)
  end

  def test_should_check_if_a_relation_can_be_clonable
    TestWidget.expects(:read_inheritable_attribute).with(:clonation_exceptions).returns([:asset_relations, :my_relation]).twice
    assert !TestWidget.send(:is_relation_clonable?, :my_relation)
    assert Widget.send(:is_relation_clonable?, :my_relation)

    assert TestWidget.send(:is_relation_clonable?, :another)
  end

  def test_should_check_if_a_relation_is_a_clonable_has_many
    TestWidget.expects(:clonation_exceptions).
      returns([:asset_relations,
                :my_relation,
                :has_many_medias,
                :has_many_medias_through,
                :has_one_reflection,
              ]).at_least_once

    relations_to_test = [
      :my_new_relation,
      :another_relation,
      :has_many_medias,
      :has_one_reflection,
      :has_many_medias_through,
      :has_one_reflection_clonable,
      :has_many_medias_clonable
    ]

    mock = relations_to_test.inject({}) do |result, value|
      mocked_value = mock(value.to_s)
      if value.to_s.include?('has_many')
        mocked_value.expects(:macro).once.returns(:has_many)
        mocked_value.stubs(:to_sym).returns(value)
        if value.to_s.include?('through')
          mocked_value.expects(:options).once.returns([:through])
        else
          mocked_value.expects(:options).once.returns([])
        end
      else
        mocked_value.expects(:macro).once.returns("not_important")
        mocked_value.expects(:to_sym).never
      end
      result[value] = mocked_value
      result
    end

    TestWidget.expects(:reflections).returns(mock).at_least_once

    assert !TestWidget.send(:is_a_clonable_has_many?, :another_relation)
    assert !TestWidget.send(:is_a_clonable_has_many?, :my_new_relation)
    assert !TestWidget.send(:is_a_clonable_has_many?, :has_one_reflection)
    assert !TestWidget.send(:is_a_clonable_has_many?, :has_one_reflection_clonable)
    assert !TestWidget.send(:is_a_clonable_has_many?, :has_many_medias)
    assert !TestWidget.send(:is_a_clonable_has_many?, :has_many_medias_through)
    assert  TestWidget.send(:is_a_clonable_has_many?, :has_many_medias_clonable)
  end

  def test_should_check_if_a_relation_is_a_clonable_has_one
    TestWidget.expects(:clonation_exceptions).
      returns([:asset_relations,
                :my_relation,
                :has_many_medias,
                :has_many_medias_throught,
                :has_one_reflection,
              ]).at_least_once

    relations_to_test = [
      :my_new_relation,
      :another_relation,
      :has_many_medias,
      :has_one_reflection,
      :has_many_medias_through,
      :has_one_reflection_clonable,
      :has_many_medias_clonable
    ]

    mock = relations_to_test.inject({}) do |result, value|
      mocked_value = mock(value.to_s)
      if value.to_s.include?('has_one')
        mocked_value.expects(:macro).once.returns(:has_one)
        mocked_value.expects(:to_sym).once.returns(value)
      else
        mocked_value.expects(:macro).once.returns("not_important")
        mocked_value.expects(:to_sym).never
      end
      result[value] = mocked_value
      result
    end

    TestWidget.expects(:reflections).returns(mock).at_least_once

    assert !TestWidget.send(:is_a_clonable_has_one?, :another_relation)
    assert !TestWidget.send(:is_a_clonable_has_one?, :my_new_relation)
    assert !TestWidget.send(:is_a_clonable_has_one?, :has_many_medias)
    assert !TestWidget.send(:is_a_clonable_has_one?, :has_many_medias_through)
    assert !TestWidget.send(:is_a_clonable_has_one?, :has_many_medias_clonable)
    assert !TestWidget.send(:is_a_clonable_has_one?, :has_one_reflection)
    assert  TestWidget.send(:is_a_clonable_has_one?, :has_one_reflection_clonable)
  end

  private

  def create_widget(options = {})
    TestWidget.create({:name => "Test Widget", :block_id => blocks(:one).id}.merge!(options))
  end
  def create_widget_with_validations(options = {})
    TestWidgetWithValidations.create({:name => "Test Widget", :block_id => blocks(:one).id}.merge!(options))
  end
end
