module UbiquoDesign
  # This middleware will return a 200 OK if the app is up and running
  class ServerStatus
    def initialize(app, connection = nil)
      @app = app
      @connection = connection || default_connection
    end

    def call(env)
      if env["PATH_INFO"] =~ /^\/server_status/
        if server_ok?
          response(200, 'OK')
        else
          response(503, 'ERROR: Database Unavailable')
        end
      else
        @app.call(env)
      end
    end

    protected

    def response(status, message)
      content_type = { "Content-Type" => "text/xml" }
      body         = "<?xml version=\"1.0\"?><message><status>#{message}</status></message>"

      [status, content_type, [body]]
    end

    def server_ok?
      ok = @connection.call if @connection.respond_to?(:call) rescue false
    end

    def default_connection
      Proc.new do
        ActiveRecord::Base.establish_connection

        ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?
      end
    end
  end
end
