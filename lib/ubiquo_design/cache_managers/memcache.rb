require 'memcache'

# Base class for widget cache
module UbiquoDesign
  module CacheManagers
    class Memcache < UbiquoDesign::CacheManagers::Base

      CONFIG = Ubiquo::Config.context(:ubiquo_design).get(:memcache)
      DATA_TIMEOUT = CONFIG[:timeout]

      class << self

        protected

        # retrieves the widget content identified by +content_id+
        def retrieve content_id
          connection.get crypted_key(content_id)
        end

        # retrieves the widgets content bty han array of +content_ids+
        def multi_retrieve content_ids, crypted = true
          unless crypted
            crypted_content_ids = []
            content_ids.each do |c_id|
              crypted_content_ids << crypted_key(c_id)
            end
          else
            crypted_content_ids = content_ids
          end
          connection.get_multi crypted_content_ids 
        end

        # Stores a widget content indexing by a +content_id+
        def store content_id, contents, expiration_time
          exp_time = expiration_time || DATA_TIMEOUT
          connection.set crypted_key(content_id), contents, exp_time
        end

        # removes the widget content from the store
        def delete content_id
          Rails.logger.debug "Widget cache expiration request for key #{content_id}"
          connection.delete crypted_key(content_id)
        end

        # Returns or initializes a memcache connection
        def connection
          @cache = MemCache.new(CONFIG[:server])
        end


      end

    end
  end
end
