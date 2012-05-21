require File.dirname(__FILE__) + '/../test_helper'

class ProxyServerTest < ActiveSupport::TestCase

  def test_should_create_proxy_server
    assert_difference 'ProxyServer.count' do
      proxy_server = create_proxy_server
      assert !proxy_server.new_record?, "#{proxy_server.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_host
    assert_no_difference "ProxyServer.count" do
      proxy_server = create_proxy_server(:host => "")
      assert proxy_server.errors.on(:host)
    end
  end

  def test_should_require_port
    assert_no_difference "ProxyServer.count" do
      proxy_server = create_proxy_server(:port => "")
      assert proxy_server.errors.on(:port)
    end
  end

  def test_should_detect_alive
    assert_not_nil d = create_proxy_server(:host => 'hostname', :port => 4000, :updated_at => 1.minutes.ago)
    d.update_attribute(:updated_at, 1.minutes.ago)
    assert d.updated_at > ProxyServer::DEAD_MINUTES.minutes.ago

    assert ProxyServer.alive.include?(d)
  end

  def test_should_destroy_obsolete
    create_proxy_server(:host => 'hostname', :port => 4000, :updated_at => 10.minutes.ago)
    assert (n = ProxyServer.obsolete.count) > 0
    assert_difference "ProxyServer.count", -n do
      ProxyServer.delete_all_obsolete
    end
  end

  def test_should_find_existing_proxy_server
    server = create_proxy_server(:host => 'hostname', :port => 4000)
    assert_equal server, ProxyServer.find_or_initialize(server.host, server.port)
  end

  def test_should_initialize_new_proxy_server
    server = ProxyServer.find_or_initialize('new_host', '80')
    assert_equal 'new_host', server.host
    assert_equal 80, server.port
  end

  private

  def create_proxy_server(options = {})
    default_options = {
      :host => "myhost",
      :port => 3001
    }
    ProxyServer.create(default_options.merge(options))
  end

  def xml_status(avail, busy)
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <status>\n    <available type=\"integer\">#{avail}</available>\n    <busy type=\"integer\">#{busy}</busy>\n  </status>\n</hash>\n"
  end
end
