module RedmineGttPrint

  # Transforms the given array of issues into JSON ready to be sent to the
  # mapfish print server
  #
  class IssuesToJson
    def initialize(issues, layout)
      @issues = issues
      @layout = layout
    end

    def self.call(issues, layout)
      new(issues, layout).call
    end

    def call
      hsh = {
        layout: @layout,
        attributes: {
          issues: @issues.map{|i| IssueToJson.attributes_hash(i)}
        }
      }

      if (features = @issues.map(&:geodata_for_print).compact).any?
        # TODO determine a proper center for the whole set of features
        center = features.first[:center]
        hsh[:attributes][:map] = IssueToJson.map_data(
          center,
          features.map{|f| f[:geojson] }
        )
      end

      hsh.to_json
    end

  end
end

