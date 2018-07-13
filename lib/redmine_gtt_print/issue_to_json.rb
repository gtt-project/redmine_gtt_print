module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  class IssueToJson
    def initialize(issue, layout)
      @issue = issue
      @layout = layout
    end

    def self.call(issue, layout)
      new(issue, layout).call
    end

    def call
      json = {
        layout: @layout,
        attributes: self.class.attributes_hash(@issue)
      }

      if data = @issue.geodata_for_print
        json[:attributes][:map] = self.class.map_data(data[:center], [data[:geojson]])
      end

      json.to_json
    end

    # the following static helpers are used by IssuesToJson as well

    def self.attributes_hash(issue)
      {
        # initially "title" was part of the print template, but it has been removed.
        id: issue.id,
        subject: issue.subject,
        description: issue.description,
        project_id: "TBD",
        project_name: "TBD",
        tracker_id: "TBD",
        tracker_name: "TBD",
        status_id: "TBD",
        status_name: "TBD",
        priority_id: "TBD",
        priority_name: "TBD",
        author_id: "TBD",
        author_name: "TBD",
        assigned_to_id: "TBD",
        assigned_to_name: "TBD",
        is_private: issue.is_private,
        start_date: issue.start_date,
        done_date: "TBD",
        estimated_hours: issue.estimated_hours,
        total_estimated_hours: issue.total_estimated_hours,
        created_on: issue.created_on,
        updated_on: issue.updated_on,
      }
    end

    def self.map_data(center, features)
      {
        center: center,
        rotation: 0,
        longitudeFirst: true,
        layers: [
          {
            geoJson: {
              features: features,
              type: "FeatureCollection",
            },
            style: {
              val1: "#FF4500",
              "*": {
                symbolizers: [{
                fillColor: "#FF0000",
                strokeWidth: 5,
                fillOpacity: 0,
                graphicName: "circle",
                rotation: "30",
                strokeDashstyle: "solid",
                strokeLinecap: "round",
                type: "point",
                graphicOpacity: 0.4,
                strokeColor: " ${val1}",
                pointRadius: 8,
                strokeOpacity: 1
              }]},
              version: "2"
            },
            type: "geojson"
          },
          {
            baseURL: "https://cyberjapandata.gsi.go.jp/xyz/std",
            imageExtension: "png",
            type: "osm"
          }
        ],
        scale: 25000,
        projection: "EPSG:3857",
        dpi: 300
      }
    end

  end
end
