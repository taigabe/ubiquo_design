require File.dirname(__FILE__) + '/../test_helper'

class DiscoveryControllerTest < ActionController::TestCase

  def test_should_create_proxy_server
    assert_difference "ProxyServer.count" do
      proxy_request
      assert_response :success
    end
    assert_not_nil assigns("proxy_server")
  end

  def test_should_update_proxy_server
    assert_not_nil server = ProxyServer.create(:host => 'hostname', :port => 4000, :updated_at => 1.minute.ago)
    initial_updated_at = server.updated_at

    assert_no_difference "ProxyServer.count" do
      proxy_request(:host => server.host, :port => server.port)
      assert_response :success
    end

    assert_not_equal initial_updated_at, server.reload.updated_at
    assert_not_nil assigns("proxy_server")
  end

  protected

  def proxy_request(options = {})
    post(:create, {:host => "127.0.0.1", :port => "80", :format => "xml", :type => "proxy_server", :locale => 'ca'}.merge(options))
  end


end
