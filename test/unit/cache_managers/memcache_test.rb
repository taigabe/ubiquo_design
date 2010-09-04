require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::MemcacheTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign::CacheManagers::Memcache
  end

  test 'store should set to memcache' do
    connection = mock()
    connection.expects(:set).with('id', 'content', @manager::DATA_TIMEOUT)
    @manager.stubs(:connection).returns(connection)
    @manager.send :store, 'id', 'content'
  end

  test 'retrieve should get from memcache' do
    connection = mock()
    connection.expects(:get).with('id')
    @manager.stubs(:connection).returns(connection)
    @manager.send :retrieve, 'id'
  end

  test 'delete should delete from memcache' do
    connection = mock()
    connection.expects(:delete).with('id')
    @manager.stubs(:connection).returns(connection)
    @manager.send :delete, 'id'
  end
end
