# frozen_string_literal: true

module RedmineGttPrint
  class MapfishSync < Mapfish

    PrintResult = ImmutableStruct.new(:pdf, :error)

    def print(job, referer = nil, user_agent = nil)
      request_print(job.json, job.layout, job.format, referer, user_agent)
    end

    def get_status(ref)
      error_msg = "get_status is not supported in sync mode"
      Rails.logger.error error_msg
      return PrintResult.new error: error_msg
    end

    def get_print(ref)
      error_msg = "get_print is not supported in sync mode"
      Rails.logger.error error_msg
      return PrintResult.new error: error_msg
    end

    private

    def request_print(json, layout, format, referer = nil, user_agent = nil)
      headers, encoded_layout = prepare_headers_and_encoded_layout(json, layout, referer, user_agent)
      url = "#{@host}/print/#{encoded_layout}/buildreport.#{format}"
      r = HTTParty.post url, body: json, headers: headers #, timeout: @timeout
      if r.success?
        PrintResult.new pdf: r.body
      else
        Rails.logger.error "failed to fetch print result from #{url} : #{r.code}\n#{r.body}"
        PrintResult.new error: r.body
      end
    end
  end
end
