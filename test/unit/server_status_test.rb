require 'test_helper'

class UbiquoDesign::ServerStatusTest < ActiveSupport::TestCase
  attr_accessor :middleware
  setup :prepare

  test "should call app if the path is not server_status" do
    env = { 'PATH_INFO' => '/test' }
    response = middleware.call(env)

    assert_equal 'main app called', response
  end

  test "should get 200 if the database is available" do
    env = { 'PATH_INFO' => '/server_status' }
    response = middleware.call(env)

    assert_equal 200, response.first
  end

  test "should get 503 if the database is not available" do
    env = { 'PATH_INFO' => '/server_status' }
    connections = [Proc.new { false },
                   Proc.new { nil },
                   Proc.new { raise ActiveRecord::ActiveRecordError.new }]
    connections.each do |unavailable|
      middleware  = build_middleware(:connection => unavailable)
      response    = middleware.call(env)

      assert_equal 503, response.first
    end
  end

  private

  def prepare
    @middleware = build_middleware
  end

  def build_middleware(options = {})
    app        = options[:app] || stub(:call => 'main app called')
    connection = options[:connection]

    UbiquoDesign::ServerStatus.new(app, connection)
  end
end
