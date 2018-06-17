module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  # TODO: fetch template capabilities
  # (https://print.***REMOVED***/print/DEMO_gtt/capabilities.json?pretty=true)
  # and determine issue attributes that have to be included from that.
  #
  class IssueToJson
    def initialize(issue)
      @issue = issue
    end

    def self.call(issue)
      new(issue).call
    end

    def call
      json = {
        layout: "A4 portrait",
        attributes: {
          title: @issue.subject,
        }
      }

      if data = @issue.geodata_for_print
        json[:attributes][:map] = map_data(data)
      end

      json.to_json
    end

    private

    def map_data(data)
      {
        center: data[:center],
        rotation: 0,
        longitudeFirst: true,
        layers: [
          {
            geoJson: {
              features: [
                data[:geojson]
              ],
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
        dpi: 72
      }
    end

  end
end
