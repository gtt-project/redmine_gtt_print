# frozen_string_literal: true

module RedmineGttPrint
  class Mapfish

    CreateJobResult = ImmutableStruct.new(:success?, :ref)
    PrintResult = ImmutableStruct.new(:pdf, :error)

    def initialize(host:)
      @host = host
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
      str = URI.escape(print_config)
      begin
        url = "#{@host}/print/#{str}/capabilities.json"
        r = HTTParty.get url
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
      if ref = request_print(job.json, job.print_config, job.format, referer, user_agent)
        CreateJobResult.new success: true, ref: ref
      else
        CreateJobResult.new
      end
    end

    # {"done"=>true, "status"=>"finished", "elapsedTime"=>6588, "waitingTime"=>0, "downloadURL"=>"/mapfish/print/report/a790a8e0-d2b9-4f27-8a83-d58a70b66568@36419944-3e1d-4b17-9aab-f56aec338242"}
    def get_status(ref)
      r = HTTParty.get "#{@host}/print/status/#{ref}.json"
      if r.success?
        json = JSON.parse r.body
        json['done'] ? :done : :running
      else
        :not_found
      end
    end

    def get_print(ref)
      url = "#{@host}/print/report/#{ref}"
      r = HTTParty.get url
      if r.success?
        PrintResult.new pdf: r.body
      else
        Rails.logger.error "failed to fetch print result from #{url} : #{r.code}\n#{r.body}"
        PrintResult.new error: r.body
      end
    end

    private

    def request_print(json, print_config, format, referer = nil, user_agent = nil)
      str = URI.escape(print_config)
      url = "#{@host}/print/#{str}/report.#{format}"
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
      r = HTTParty.post url, body: json, headers: headers
      if r.success?
        json = JSON.parse r.body
        json['ref']
      else
        Rails.logger.error "failed to request print at #{url}: #{r.code}\n#{r.body}"
        false
      end
    end

    def find_print_configs
      r = HTTParty.get "#{@host}/print/apps.json"
      if r.success?
        JSON.parse r.body
      else
        Rails.logger.error "failed to fetch print configs: #{r.code}"
        []
      end
    end

  end
end
