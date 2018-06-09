module RedmineGttPrint
  class Mapfish
    def initialize(host:)
      @host = host
    end

    def templates
      @templates ||= find_templates
    end

    private

    def find_templates
      r = HTTParty.get "#{@host}/print/apps.json"
      if r.success?
        JSON.parse r.body
      else
        Rails.logger.error "failed to fetch print templates: #{r.status}"
        []
      end
    end

  end
end
