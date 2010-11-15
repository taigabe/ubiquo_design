require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::MemcacheTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign::CacheManagers::Memcache
  end

  test 'store should set to memcache' do
    connection = mock()
    connection.expects(:set).with(@manager.send('crypted_key', 'id'), 'content', 2.seconds)
    @manager.stubs(:connection).returns(connection)
    @manager.send :store, 'id', 'content', 2.seconds
  end

  test 'retrieve should get from memcache' do
    connection = mock()
    connection.expects(:get).with(@manager.send('crypted_key', 'id'))
    @manager.stubs(:connection).returns(connection)
    @manager.send :retrieve, 'id'
  end

  test 'delete should delete from memcache' do
    connection = mock()
    connection.expects(:delete).with(@manager.send('crypted_key', 'id'))
    @manager.stubs(:connection).returns(connection)
    @manager.send :delete, 'id'
  end
end
