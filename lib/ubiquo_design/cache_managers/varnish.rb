module UbiquoDesign
  module CacheManagers
    # Varnish implementation for the cache manager
    class Varnish < UbiquoDesign::CacheManagers::Base

#      CONFIG = Ubiquo::Config.context(:ubiquo_design).get(:varnish)

      class << self

        # This method is called when rendering +page+ and returns a hash where
        # the keys are the ids of the page widgets that are esi widgets,
        # and the value is an esi:include tag
        def multi_get(page, options = {})
          {}.tap do |widgets_by_id|
            request = options[:scope].request
            page.blocks.each do |block|
              block.real_block.widgets.each do |widget|
                if esi_widget?(widget)
                  new_params = request.query_parameters.merge('widget' => widget.id)
                  esi_url = request.url.gsub("?#{request.query_string}", '') + "?#{new_params.to_query}"
                  widgets_by_id[widget.id] = "<esi:include src=#{esi_url.to_json} />"
                end
              end
            end
          end
        end

        # Caches the content of a widget
        # Simply return, since the real caching is done by Varnish when the request is finished
        def cache(widget_id, contents, options = {}); end

       # Returns true if the widget is an esi widget
        def esi_widget?(widget)
          # TODO
          defined? ESI_ENABLED
        end

        # Expires the applicable content of a widget given its id
        # This means all the urls where the widget is cached
        # +widget+ is a Widget instance
        def expire(widget)
          Rails.logger.debug "-- Expiring Varnish --"

          # We ban all the urls of the related page that also contain the widget id
          # e.g. /url/of/page?param=4&widget=42
          ban_url = Regexp.escape(widget.page.url + "?") + ".*widget=#{widget.id}"

          # And we also ban all the urls that do not contain the widget param
          # (i.e. the "full page", which can have different representations if
          # it has different params).
          # This is needed since else the esi fragment would be new,
          # but the page would still be cached.
          # The other cached pages with the "widget" param are in fact
          # other widgets of this page, which have not been modified
          # e.g. /url/of/page?param=4 (this will be expired because !~)
          ban_negative_url = Regexp.escape(widget.page.url + '?') + ".*widget="

          # Now do the real job. This is the correct order to avoid recaching old data
          ban(ban_url)
          ban_negative(ban_negative_url)
        end

        # Expires a +page+, with all its possibles urls and params
        def expire_page(page)
          # We cannot simply ban url_page* since url_page could be a segment of
          # another page, so:
          # ban the url_page with params
          ban(Regexp.escape(page.url + "?"))
          # ban the exact page url, with or without trailing slash
          ban(Regexp.escape(page.url) + "[\/]?$")
        end

        protected

        # Bans all urls that match +url+ (which is interpreted as a regexp)
        def ban(url)
          varnish_request('BAN', url)
        end

        # Bans all urls not matching +url+
        def ban_negative(url)
          varnish_request('BAN_NEG', url)
        end

        # removes the widget content from the store
        def varnish_request method, url
          Rails.logger.debug "Varnish #{method} request for url #{url}"
          # TODO deal with multiple servers
          begin
            http = Net::HTTP.new(VARNISH_SERVER, VARNISH_PORT)
            http.set_debug_output($stderr) # TODO temporal
            http.send_request(method, url)
          rescue
            Rails.logger.warn "Cache is not available, impossible to delete cache: "+ $!.inspect
          end
        end

       end

    end
  end
end
