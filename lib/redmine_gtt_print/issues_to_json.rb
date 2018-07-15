module RedmineGttPrint

  # Transforms the given array of issues into JSON ready to be sent to the
  # mapfish print server
  #
  class IssuesToJson
    def initialize(issues, layout, other_attributes = {})
      @issues = issues
      @layout = layout
      @other_attributes = other_attributes
    end

    def self.call(*_)
      new(*_).call
    end

    def call
      hsh = {
        layout: @layout,
        attributes: {
          issues: @issues.map{|i|
            IssueToJson.attributes_hash(i, @other_attributes)
          }
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

