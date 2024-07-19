# frozen_string_literal: true

module RedmineGttPrint
  class MapfishAsync < Mapfish

    CreateJobResult = ImmutableStruct.new(:success?, :ref)
    PrintResult = ImmutableStruct.new(:pdf, :error)

    def print(job, referer = nil, user_agent = nil)
      if ref = request_print(job.json, job.layout, job.format, referer, user_agent)
        CreateJobResult.new success: true, ref: ref
      else
        CreateJobResult.new
      end
    end

    # {"done"=>true, "status"=>"finished", "elapsedTime"=>6588, "waitingTime"=>0, "downloadURL"=>"/mapfish/print/report/a790a8e0-d2b9-4f27-8a83-d58a70b66568@36419944-3e1d-4b17-9aab-f56aec338242"}
    def get_status(ref)
      r = HTTParty.get "#{@host}/print/status/#{ref}.json", timeout: @timeout
      if r.success?
        json = JSON.parse r.body
        json['done'] ? :done : :running
      else
        :not_found
      end
    end

    def get_print(ref)
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
      url = "#{@host}/print/#{str}/report.#{format}"
      r = HTTParty.post url, body: json, headers: headers, timeout: @timeout
      if r.success?
        json = JSON.parse r.body
        json['ref']
      else
        Rails.logger.error "failed to request print at #{url}: #{r.code}\n#{r.body}"
        false
      end
    end
  end
end
