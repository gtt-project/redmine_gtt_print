# frozen_string_literal: true
require 'rack/utils'

module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  class IssueToJson
    include Rails.application.routes.url_helpers, ApplicationHelper

    # what works in the mailer is good enough for the image URL generation as
    # well
    def default_url_options
      ::Mailer.default_url_options
    end

    def initialize(issue, layout, other_attributes = {})
      @issue = issue
      @layout = layout
      @other_attributes = other_attributes

      @attachment_tag_pattern1 = nil
      @attachment_tag_pattern2 = nil
      if Redmine::Plugin.installed?(:redmine_gtt_custom)
        @attachment_tag_pattern1 = get_attachment_tag_pattern(Setting.plugin_redmine_gtt_custom["attachment_tag_prefixes1"])
        @attachment_tag_pattern2 = get_attachment_tag_pattern(Setting.plugin_redmine_gtt_custom["attachment_tag_prefixes2"])
      end
    end

    def self.call(*_)
      new(*_).call
    end

    def call
      json = {
        layout: @layout,
        attributes: self.class.attributes_hash(@issue,
                                               @layout,
                                               @other_attributes,
                                               image_urls(@issue))
      }

      scale = nil
      basemap_url = nil
      if !@other_attributes.nil?
        scale = @other_attributes[:scale]
        basemap_url = @other_attributes[:basemap_url]
      end
      if data = @issue.geodata_for_print
        json[:attributes][:map] = self.class.map_data(data[:center], [data[:geojson]],
          scale, basemap_url)
      end

      context = {
        issue: @issue, other_attributes: @other_attributes, json: json
      }
      Redmine::Hook.call_hook(:redmine_gtt_print_issue_to_json, context)

      json.to_json
    end

    def image_urls(issue)
      before_image_urls = []
      after_image_urls = []
      other_image_urls = []
      issue.attachments.map do |a|
        if a.image?
          if a.description.nil? or (@attachment_tag_pattern1.nil? and @attachment_tag_pattern2.nil?)
            other_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
          elsif a.description.match(@attachment_tag_pattern1)
            before_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
          elsif a.description.match(@attachment_tag_pattern2)
            after_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
          else
            other_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
          end
        end
      end
      return {
        "before" => before_image_urls,
        "after" => after_image_urls,
        "other" => other_image_urls
      }
    end

    # the following static helpers are used by IssuesToJson as well

    def self.attributes_hash(issue, layout, other_attributes, image_urls)
      custom_fields = issue_custom_fields_by_name issue



      result = {
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
        author_name: issue.author&.name || "",
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

        # Image attachments (max. 4 iamges for each tags)
        before_image_url_1: image_urls["before"][0] || "../#{layout}/blank.png",
        before_image_url_2: image_urls["before"][1] || "../#{layout}/blank.png",
        before_image_url_3: image_urls["before"][2] || "../#{layout}/blank.png",
        before_image_url_4: image_urls["before"][3] || "../#{layout}/blank.png",
        after_image_url_1: image_urls["after"][0] || "../#{layout}/blank.png",
        after_image_url_2: image_urls["after"][1] || "../#{layout}/blank.png",
        after_image_url_3: image_urls["after"][2] || "../#{layout}/blank.png",
        after_image_url_4: image_urls["after"][3] || "../#{layout}/blank.png",
        other_image_url_1: image_urls["other"][0] || "../#{layout}/blank.png",
        other_image_url_2: image_urls["other"][1] || "../#{layout}/blank.png",
        other_image_url_3: image_urls["other"][2] || "../#{layout}/blank.png",
        other_image_url_4: image_urls["other"][3] || "../#{layout}/blank.png",

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

      custom_fields.each{|name, value| result["cf_#{name}"] = value || ""}

      result
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
            baseURL: basemap_url.nil? ? "https://cyberjapandata.gsi.go.jp/xyz/std" : basemap_url.sub(/\/{z}\/{x}\/{y}.png.*/,''),
            customParams: (basemap_url.present? and basemap_url.partition("?").last.present?) ? Rack::Utils.parse_nested_query(basemap_url.partition("?").last) : {},
            imageExtension: "png",
            type: "osm"
          }
        ],
        scale: scale.nil? ? 25000 : scale,
        projection: "EPSG:3857",
        dpi: 144
      }
    end

  end
end
