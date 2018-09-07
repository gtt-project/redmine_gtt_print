# frozen_string_literal: true

module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  class IssueToJson
    include Rails.application.routes.url_helpers

    # what works in the mailer is good enough for the image URL generation as
    # well
    def default_url_options
      ::Mailer.default_url_options
    end

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
        attributes: self.class.attributes_hash(@issue,
                                               @other_attributes,
                                               image_urls(@issue))
      }

      if data = @issue.geodata_for_print
        json[:attributes][:map] = self.class.map_data(data[:center], [data[:geojson]],
          @other_attributes[:scale], @other_attributes[:basemap_url])
      end

      context = {
        issue: @issue, other_attributes: @other_attributes, json: json
      }
      Redmine::Hook.call_hook(:redmine_gtt_print_issue_to_json, context)

      json.to_json
    end

    def image_urls(issue)
      issue.attachments.map do |a|
        if a.image?
          download_named_attachment_url(a, a.filename, key: User.current.api_key)
        end
      end.compact
    end

    # the following static helpers are used by IssuesToJson as well

    def self.attributes_hash(issue, other_attributes, image_urls)
      custom_fields = issue_custom_fields_by_name issue

      {
        id: issue.id,
        subject: issue.subject,
        project_id: issue.project_id,
        project_name: issue.project.name,
        tracker_id: issue.tracker_id,
        tracker_name: issue.tracker.name,
        status_id: issue.status_id,
        status_name: issue.status.name,
        priority_id: issue.priority_id,
        priority_name: issue.priority.name,
        # category_id: issue.category_id,
        author_id: issue.author_id,
        author_name: issue.author.name,
        assigned_to_id: issue.assigned_to_id,
        assigned_to_name: issue.assigned_to&.name || "",
        description: issue.description,
        is_private: issue.is_private,
        start_date: issue.start_date,
        done_date: issue.closed_on,
        # due_date: issue.due_date,
        estimated_hours: issue.estimated_hours,
        created_on: issue.created_on,
        updated_on: issue.updated_on,
        last_notes: issue.last_notes || "",

        # Custom text
        custom_text: other_attributes[:custom_text],

        # Custom fields fbased on names
        cf_通報者: custom_fields["通報者"] || "",
        cf_通報手段: custom_fields["通報手段"] || "",
        cf_通報者電話番号: custom_fields["通報者電話番号"] || "",
        cf_通報者メールアドレス: custom_fields["通報者メールアドレス"] || "",
        cf_現地住所: custom_fields["現地住所"] || "",

        # Image attachments (max. 4 iamges)
        image_url_1: image_urls[0] || "../#{RedmineGttPrint.tracker_config(issue.tracker)}/blank.png",
        image_url_2: image_urls[1] || "../#{RedmineGttPrint.tracker_config(issue.tracker)}/blank.png",
        image_url_3: image_urls[2] || "../#{RedmineGttPrint.tracker_config(issue.tracker)}/blank.png",
        image_url_4: image_urls[3] || "../#{RedmineGttPrint.tracker_config(issue.tracker)}/blank.png",

        # Experimental
        # issue: issue,
        # project: (Project.find issue.project_id),
        # tracker: (Tracker.find issue.tracker_id),
        # status: (IssueStatus.find issue.status_id),
        # priority: (IssuePriority.find issue.priority_id),
        # author: (User.find issue.author_id),
        # assigned_to: (User.find issue.assigned_to_id),

#         journals: issue.visible_journals_with_index.map{|j|
#           {
#             user: { login: j.user&.login, id: j.user&.id, name: j.user&.name },
#             notes: j.notes,
#             created_on: j.created_on,
#             details: j.visible_details.map{|d|
#               {
#                 property: d.property,
#                 name: d.prop_key,
#                 old_value: d.old_value,
#                 new_value: d.new_value
#               }
#             }
#           }
#         },
#         attachments: issue.attachments.map{|a|
#           {
#             id: a.id,
#             filename: a.filename,
#             filesize: a.filesize,
#             content_type: a.content_type,
#             description: a.description,
#             content_url: nil, # this is a bit more complex as we do not have access to URL generation methods here.
#           }
#         }
      }
    end

    def self.issue_custom_fields_by_name(issue)
      Hash[
        issue.visible_custom_field_values.map{|cfv|
          [cfv.custom_field.name, cfv.value]
        }
      ]
    end

    def self.map_data(center, features, scale, basemap_url)
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
        scale: scale,
        projection: "EPSG:3857",
        dpi: 144
      }
    end

  end
end
