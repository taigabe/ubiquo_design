module UbiquoDesign
  module CacheManagers
    # Varnish implementation for the cache manager
    class Varnish < UbiquoDesign::CacheManagers::Base

      class << self

        # This method is called when rendering +page+ and returns a hash where
        # the keys are the ids of the page widgets that are esi widgets,
        # and the value is an esi:include tag
        def multi_get(page, options = {})
          {}.tap do |widgets_by_id|
            request = options[:scope].request
            page.blocks.each do |block|
              block.real_block.widgets.each do |widget|
                if render_esi_widget?(widget)
                  esi_url = if widget.has_unique_url?
                    widget.url
                  else
                    new_params = request.query_parameters.merge('widget' => widget.id)
                    request.url.gsub("?#{request.query_string}", '') + "?#{new_params.to_query}"
                  end
                  widgets_by_id[widget.id] = "<esi:include src=#{esi_url.to_json} />"
                end
              end
            end
          end
        end

        # Caches the content of a widget
        # Simply return, since the real caching is done by Varnish when the request is finished
        def cache(widget_id, contents, options = {}); end

        # Returns true if a widget is a esi widget and we are rendering widgets as esi
        def render_esi_widget?(widget)
          defined?(ESI_RENDERING_ENABLED) && esi_widget?(widget)
        end

        # Returns true if the widget is an esi widget
        def esi_widget?(widget)
          !widget.respond_to?(:skip_esi?) || !widget.skip_esi?
        end

        # Expires the applicable content of a widget given its id
        # This means all the urls where the widget is cached
        # +widget+ is a Widget instance
        # +options+ are used in the absolute_url calculation, and includes at minimum
        #   the :scope of the expiration.
        #   Use :loose => true is you want the url to match loosely at the right
        #     (e.g. to expire too /my/url/extended if the page is at /my/url)
        def expire(widget, options = {})
          Rails.logger.debug "Expiring widget ##{widget.id} in Varnish"

          base_url = widget.page.absolute_url(options)
          widget_url = widget.url.gsub(/\?.*$/, '') if widget.has_unique_url?
          loose = "[^\\?]*" if options[:loose]

          # We ban all the urls of the related page that also contain the widget id
          # e.g. /url/of/page?param=4&widget=42
          widget_urls = [widget_url || base_url, "#{loose}\\?.*widget=#{widget.id}"]

          # And we also ban all the urls that do not contain the widget param
          # (i.e. the "full page", which can have different representations if
          # it has different params).
          # This is needed since else the esi fragment would be new,
          # but the page would still be cached.
          # The other cached pages with this page url and the "widget" param
          # are in fact other widgets of this page, which have not been modified
          # e.g. /url/of/page?param=4 will be expired; /url/of/page?param=4&widget=1 won't.
          page_urls = [base_url, "#{loose}($|\\?(?!.*(?<=[\\?|&])widget=))"]

          # Now do the real job. This is the correct order to avoid recaching old data
          #
          # Only expire the widget if is an esi widget (to skip unnecessary bans for skip_esi widgets)

          ban(widget_urls) if esi_widget?(widget)

          # And only expire the page if the widget is not shared (too many potential pages)

          ban(page_urls) unless widget.has_unique_url?
        end

        # Expires a +page+, with all its possibles urls and params
        def expire_page(page, options = {})
          return unless page
          Rails.logger.debug "Expiring page ##{page.id} in Varnish"
          if options[:include_child_pages]
            options[:child_slugs] = page.updated_today_articles(:slug).map(&:slug)
            options[:child_slugs].map! { |slug| "hemeroteca_articles/#{slug}" } if page.absolute_url =~ %r{.*/hemeroteca/.*$}
          end
          expire_url(page.absolute_url, nil, options)
        end

        def expire_url(url, regexp = nil, options = {})
          return unless url
          Rails.logger.debug "Expiring url '#{url}' in Varnish"
          options_without_child_slugs = options.except(:child_slugs)
          # We ban the url with the given regexp, if any
          ban([url, regexp]) if regexp
          # We cannot simply ban url* since url could be a segment of
          # another page, so:
          # ban the url with params
          ban([url, "\\?"], options_without_child_slugs)
          # ban the exact page url, with or without trailing slash
          ban([url, "[\/]?$"], options_without_child_slugs.merge(:warmup => true))
          if options[:include_section_pages]
            ban([url, "\/(?\!noticia)"], options_without_child_slugs)
          end
          # ban current month news
          ban([url, "\*"], options) if options[:include_child_pages]

          if Settings[:application][:https_all] && url =~ /http:\/\//
            url.sub!('http://', 'https://')
            varnish_url_warmup(url, !!options.fetch(:apply_on_every_locale, true))
          end
        end

        # Overwrites the traditional model expiration to make use of the new storage of policies
        def expire_by_model(instance, cache_policy_context = nil)
          return if instance.cache_expiration_denied.present?

          affected_widgets = self.expirable_widgets(instance)
          if affected_widgets.present?
            # Note that if we don't check if there are expirable widgets,
            # a lot of unnecessary jobs would be created
            if delayed_expiration?
              ExpirationJob.launch(instance)
            else
              varnish_expire_by_model(instance, affected_widgets)
            end
          end
        end

        def uhook_run_behaviour(controller)
          controller.varnish_expires_in ::Widget::WIDGET_TTL[:default] if controller.widget_request?
        end

        protected

        def delayed_expiration?
          key = :async_varnish_expiration
          context = Ubiquo::Settings[:ubiquo_design]
          context.option_exists?(key) && context[key]
        end

        # Given the defined policies, returns which widget types have to be expired
        # by the change in this instance (self).
        # The returned value is a hash of {:widget_key => policy_proc_or_nil}
        def expirable_widgets(instance)
          expirable_widgets = {}
          policies = UbiquoDesign::CachePolicies.get(:varnish)
          # Policies defined with +expire_widget+
          policies.each_pair do |widget_key, model_hash|
            model_hash.keys.each do |affected_model|
              if instance.is_a?(affected_model.to_s.constantize)
                expirable_widgets[widget_key] = policies[widget_key][affected_model]
              end
            end
          end
          expirable_widgets
        end


        # Custom expiration using varnish policies
        # +affected_widgets+ is an already loaded result of +expirable_widgets+ to avoid a double call
        def varnish_expire_by_model(instance, affected_widgets = nil)

          # now expire those widgets affected by a +expire_widget+ policy
          widgets_to_expire = []
          widgets_and_policies = affected_widgets || expirable_widgets(instance)
          widgets_and_policies.each_pair do |key, policy|
            # the special :custom group gives the user the power to return which widgets wants to expire
            if key == :custom
              widgets_to_expire += policy.call(instance)
            else
              # find all the widgets from type +key+ which are in published pages
              Widget.class_by_key(key).published.each do |widget|
                # skip the widgets when they have a defined block and it does not return true
                unless policy && !policy.call(widget, instance)
                  widgets_to_expire << [widget, {:scope => instance}]
                end
              end
            end
          end

          widgets_to_expire.uniq.each do |widget, options|
            widget.expire(options || {})
          end
        end

        # Bans all urls that match +url+, which is an array with a
        # regexp-escapable part and an already escaped one that is appended
        # after the final slash.
        # Note that +url+ is strictly interpreted, as '^' is prepended
        def ban(url, options = {})
          # Get the base url from the related page, without the possible
          # trailing slash. It is appended as optional later (to expire both)
          base_url = url.first.gsub(/\/$/, '')

          # Parse the url and separate the host and the path+query
          parsed_url_for_host = URI.parse(url.first)
          host = parsed_url_for_host.host
          warmup_url = options[:warmup] ? url.first : nil

          # delete the host from the base_url
          if Rails.env.development?
            port = parsed_url_for_host.port
            base_url_without_host = base_url.sub("#{parsed_url_for_host.scheme}://#{host}:#{port}", '')
          else
            base_url_without_host = base_url.sub("#{parsed_url_for_host.scheme}://#{host}", '')
          end

          # Varnish 2.1 required to double-escape in order to get it as a correct regexp
          # result_url = Regexp.escape(base_url_without_host).gsub('\\'){'\\\\'} + '/?' + url.last
          # Varnish 3 needs it only escaped once
          if options[:include_child_pages]
            result_url = '^' + Regexp.escape(base_url_without_host) + '/' + url.last
            warmup_url = if options[:child_slugs].try(:any?)
                            timestamp = today_timestamp(base_url)
                            new_url = url_without_timestamp(base_url)
                            options[:child_slugs].map { |slug| "#{new_url}#{timestamp}/#{slug}" }
                          else
                            nil
                          end
          elsif options[:subdomain_portada]
            result_url = '(\/$|\/(es|en|eu|fr))$'
            warmup_url = base_url
          else
            result_url = '^' + Regexp.escape(base_url_without_host) + '/?' + url.last
          end
          varnish_request('BAN', result_url, host, warmup_url, !!options.fetch(:apply_on_every_locale, true))
        end

        # Sends a request with the required +method+ to the given +url+
        # The +host+ parameter, if supplied, is used as the "Host:" header
        def varnish_request(method, url, host = nil, original_urls = nil, translate_all_locales = true)
          headers = {'Host' => host} if host

          Rails.logger.debug "Varnish #{method} request for url #{url} and host #{host}"

          begin
            http = Net::HTTP.new(Ubiquo::Settings[:application][:varnish_host],
              Ubiquo::Settings[:application][:varnish_port])
            #http.set_debug_output($stderr)
            http.send_request(method, url, nil, headers || {})
          rescue
            Rails.logger.warn "Cache is not available, impossible to delete cache: "+ $!.inspect
          end
        end

        private

        def timestamp_slug(url)
          url[/([^\/]+)$/]
        end

        def url_without_timestamp(url)
          url[/.*\//]
        end

        def today_timestamp(url)
          current_timestamp = timestamp_slug(url)
          case current_timestamp
          when /^\d{4}-\d{2}-\d{2}$/
            Time.zone.now.strftime("%Y-%m-%d")
          when /^(\S*)_\d{4}-\d{2}-\d{2}-(\d{2})-(\d{2})$/
            "#{$1}_#{Time.zone.now.strftime("%Y-%m-%d")}-#{$2}-#{$3}"
          else
            "#{current_timestamp}#{Time.zone.now.strftime('%d')}"
          end
        end

      end

    end
  end
end
