class DiscoveryController < ApplicationController

  protect_from_forgery :except => [:create, :update]

  def create
    respond_to do |format|
      case params[:type].to_sym
      when :proxy_server
        if params[:host].present? && params[:port].present?
          @proxy_server = ProxyServer.find_or_initialize(params[:host], params[:port])
          @proxy_server.updated_at = Time.now # to force updated

          if (@proxy_server.save)
            format.xml{ head :ok }
          else
            format.xml{ head 400 }
          end
        else
          format.xml{ head 400 }
        end
      else
        format.xml{ head 400 }
      end
    end
  end
end
