module RedmineGttPrint
  class Mapfish

    CreateJobResult = ImmutableStruct.new(:success?, :ref)
    PrintResult = ImmutableStruct.new(:pdf, :error)

    def initialize(host:)
      @host = host
    end

    def templates
      @templates ||= find_templates
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

    def print_issue(issue, template, format: 'pdf')
      json = IssueToJson.(issue)
      if ref = request_print(json, template, format)
        CreateJobResult.new success: true, ref: ref
      else
        CreateJobResult.new
      end
    end

    private

    def request_print(json, template, format)
      url = "#{@host}/print/#{template}/report.#{format}"
      #(File.open("/tmp/mapfish.json", "wb") << json).close
      r = HTTParty.post url, body: json, headers: { 'Content-Type' => 'application/json' }
      if r.success?
        json = JSON.parse r.body
        json['ref']
      else
        Rails.logger.error "failed to request print at #{url}: #{r.code}\n#{r.body}"
        false
      end
    end

    def find_templates
      r = HTTParty.get "#{@host}/print/apps.json"
      if r.success?
        JSON.parse r.body
      else
        Rails.logger.error "failed to fetch print templates: #{r.code}"
        []
      end
    end

  end
end
