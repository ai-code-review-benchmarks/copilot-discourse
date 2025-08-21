# frozen_string_literal: true

module Middleware
  class CrawlerHooks
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      status, headers, response = @app.call(env)

      if status == 200 && headers["Content-Type"]&.include?("text/html") &&
           CrawlerDetection.crawler?(request.user_agent, request.get_header("HTTP_VIA"))
        response = transform_response(request:, response:)
      end

      [status, headers, response]
    end

    private

    def transform_response(request:, response:)
      locale = request.params[Discourse::LOCALE_PARAM]

      if SiteSetting.content_localization_enabled &&
           SiteSetting.content_localization_crawler_param && locale.present?
        html_fragment = Nokogiri::HTML5.parse(response.body)

        html_fragment
          .css("a")
          .each do |link|
            href = link["href"]
            next if href.blank? || !href.start_with?("/", Discourse.base_url)

            uri = Addressable::URI.parse(href)
            uri.query_values = (uri.query_values || {}).merge(Discourse::LOCALE_PARAM => locale)
            link["href"] = uri.to_s
          end

        transformed_html = html_fragment.to_html
        return [transformed_html || response]
      end

      response
    end
  end
end
