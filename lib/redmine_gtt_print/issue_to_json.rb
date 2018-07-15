module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  class IssueToJson
    def initialize(issue, layout, other_attributes = {})
      @issue = issue
      @layout = layout
      @other_attributes = other_attributes
    end

    def self.call(*_)
      new(*_).call
    end

    def call
      json = {
        layout: @layout,
        attributes: self.class.attributes_hash(@issue, @other_attributes)
      }

      if data = @issue.geodata_for_print
        json[:attributes][:map] = self.class.map_data(data[:center], [data[:geojson]])
      end

      json.to_json
    end

    # the following static helpers are used by IssuesToJson as well

    def self.attributes_hash(issue, other_attributes)
      {
        id: issue.id,
        subject: issue.subject,
        project_id: issue.project_id,
        project_name: "WIP",
        tracker_id: issue.tracker_id,
        tracker_name: "WIP",
        status_id: issue.status_id,
        status_name: "WIP",
        priority_id: issue.priority_id,
        priority_name: "WIP",
        # category_id: issue.category_id,
        author_id: issue.author_id,
        author_name: "WIP",
        assigned_to_id: issue.assigned_to_id,
        assigned_to_name: "WIP",
        description: issue.description,
        is_private: issue.is_private,
        start_date: issue.start_date,
        done_date: issue.closed_on,
        # due_date: issue.due_date,
        estimated_hours: issue.estimated_hours,
        total_estimated_hours: "WIP",
        created_on: issue.created_on,
        updated_on: issue.updated_on,

        # Custom text
        # custom_text: other_attributes[:custom_text]

        # Experimental
        # issue: issue,
        # project: (Project.find issue.project_id),
        # tracker: (Tracker.find issue.tracker_id),
        # status: (Status.find issue.status_id),
        # priority: (Priority.find issue.priority_id),
        # author: (Author.find issue.author_id),
        # assigned_to: (Assigned_to.find issue.assigned_to_id),
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
        dpi: 144
      }
    end

  end
end
