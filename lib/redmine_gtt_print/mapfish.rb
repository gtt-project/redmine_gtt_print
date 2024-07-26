# frozen_string_literal: true

module RedmineGttPrint
  class Mapfish
    def initialize(host:, timeout: nil)
      @host = host
      @timeout = timeout
    end

    def print_configs
      @print_configs ||= find_print_configs
    end

    def layouts(print_config)
      Array(print_config).map do |cfg|
        if caps = get_capabilities(cfg) and layouts = caps['layouts']
          layouts.map{|l|l['name']}
        end
      end.compact.flatten
    end

    # returns capabilities document for the given print config,
    # nil if no print_config is given or no capabilities were found for it.
    def get_capabilities(print_config)
      return unless print_config
      str = URI.encode_www_form_component(print_config)
      begin
        url = "#{@host}/print/#{str}/capabilities.json"
        r = HTTParty.get url, timeout: @timeout
        if r.success?
          return JSON.parse r.body
        else
          Rails.logger.error "failed to get capabilities from #{url} : #{r.code}\n#{r.body}"
          return nil
        end
      rescue HTTParty::Error, StandardError => e
        Rails.logger.error "failed to get capabilities from #{url}\n#{e}"
        return nil
      end
    end

    def print(job, referer = nil, user_agent = nil)
      raise NotImplementedError
    end

    def get_status(ref)
      raise NotImplementedError
    end

    def get_print(ref)
      raise NotImplementedError
    end

    private

    def prepare_headers_and_encoded_layout(json, layout, referer, user_agent)
      if Rails.env.development?
        (File.open(Rails.root.join("tmp/mapfish.json"), "wb") << json).close
      end
      headers = {
        'Content-Type' => 'application/json'
      }
      headers['Referer'] = referer if referer.present?
      headers['User-Agent'] = user_agent if user_agent.present?
      encoded_layout = URI.encode_www_form_component(layout)
      return headers, encoded_layout
    end

    def request_print(json, layout, format, referer = nil, user_agent = nil)
      raise NotImplementedError
    end

    def find_print_configs
      begin
        r = HTTParty.get "#{@host}/print/apps.json", timeout: @timeout
        if r.success?
          JSON.parse r.body
        else
          Rails.logger.error "failed to fetch print configs: #{r.code}"
          []
        end
      rescue HTTParty::Error, StandardError => e
        Rails.logger.error "failed to connect to print server "
        []
      end
    end
  end
end
