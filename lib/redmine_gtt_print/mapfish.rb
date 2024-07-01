# frozen_string_literal: true

module RedmineGttPrint
  class Mapfish

    CreateJobResult = ImmutableStruct.new(:success?, :ref)
    PrintResult = ImmutableStruct.new(:pdf, :error)

    def initialize(host:, timeout: nil, is_sync: false)
      @host = host
      @timeout = timeout
      @is_sync = is_sync
    end

    def is_sync?
      @is_sync
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
      if !is_sync?
        if ref = request_print(job.json, job.layout, job.format, referer, user_agent)
          CreateJobResult.new success: true, ref: ref
        else
          CreateJobResult.new
        end
      else
        request_print(job.json, job.layout, job.format, referer, user_agent)
      end
    end

    # {"done"=>true, "status"=>"finished", "elapsedTime"=>6588, "waitingTime"=>0, "downloadURL"=>"/mapfish/print/report/a790a8e0-d2b9-4f27-8a83-d58a70b66568@36419944-3e1d-4b17-9aab-f56aec338242"}
    def get_status(ref)
      if is_sync?
        error_msg = "get_status is not supported in sync mode"
        Rails.logger.error error_msg
        return PrintResult.new error: error_msg
      end
      r = HTTParty.get "#{@host}/print/status/#{ref}.json", timeout: @timeout
      if r.success?
        json = JSON.parse r.body
        json['done'] ? :done : :running
      else
        :not_found
      end
    end

    def get_print(ref)
      if is_sync?
        error_msg = "get_print is not supported in sync mode"
        Rails.logger.error error_msg
        return PrintResult.new error: error_msg
      end
      url = "#{@host}/print/report/#{ref}"
      r = HTTParty.get url, timeout: @timeout
      if r.success?
        PrintResult.new pdf: r.body
      else
        Rails.logger.error "failed to fetch print result from #{url} : #{r.code}\n#{r.body}"
        PrintResult.new error: r.body
      end
    end

    private

    def request_print(json, layout, format, referer = nil, user_agent = nil)
      if Rails.env.development?
        (File.open(Rails.root.join("tmp/mapfish.json"), "wb") << json).close
      end
      headers = {
        'Content-Type' => 'application/json'
      }
      if !referer.nil?
        headers['Referer'] = referer
      end
      if !user_agent.nil?
        headers['User-Agent'] = user_agent
      end
      str = URI.encode_www_form_component(layout)
      if !is_sync?
        url = "#{@host}/print/#{str}/report.#{format}"
        r = HTTParty.post url, body: json, headers: headers, timeout: @timeout
        if r.success?
          json = JSON.parse r.body
          json['ref']
        else
          Rails.logger.error "failed to request print at #{url}: #{r.code}\n#{r.body}"
          false
        end
      else
        url = "#{@host}/print/#{str}/buildreport.#{format}"
        r = HTTParty.post url, body: json, headers: headers #, timeout: @timeout
        if r.success?
          PrintResult.new pdf: r.body
        else
          Rails.logger.error "failed to fetch print result from #{url} : #{r.code}\n#{r.body}"
          PrintResult.new error: r.body
        end
      end
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
