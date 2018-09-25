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
      if caps = get_capabilities(print_config) and layouts = caps['layouts']
        layouts.map{|l|l['name']}
      end
    end

    # returns capabilities document for the given print config,
    # nil if no print_config is given or no capabilities were found for it.
    def get_capabilities(print_config)
      return unless print_config
      str = URI.escape(print_config)
      r = HTTParty.get "#{@host}/print/#{str}/capabilities.json"
      if r.success?
        return JSON.parse r.body
      end
    end

    def print(job, referer, user_agent)
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

    def request_print(json, print_config, format, referer, user_agent)
      str = URI.escape(print_config)
      url = "#{@host}/print/#{str}/report.#{format}"
      if Rails.env.development?
        (File.open(Rails.root.join("tmp/mapfish.json"), "wb") << json).close
      end
      r = HTTParty.post url, body: json, headers: {
        'Content-Type' => 'application/json',
        'Referer' => referer,
        'User-Agent' => user_agent
      }
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
