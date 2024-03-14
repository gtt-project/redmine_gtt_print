# frozen_string_literal: true
require 'rack/utils'

module RedmineGttPrint

  # Transforms the given issue into JSON ready to be sent to the mapfish print
  # server.
  #
  class IssueToJson
    include Rails.application.routes.url_helpers
    include ApplicationHelper

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

    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    def call
      json = {
        layout: @layout,
        attributes: self.class.attributes_hash(@issue,
                                               @layout,
                                               @other_attributes,
                                               attachments_datasource(@issue.attachments),
                                               image_urls(@issue.attachments))
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
      else
        project = Project.find(@issue.project_id)
        if data = project.geodata_for_print
          json[:attributes][:map] = self.class.map_data(data[:center], [],
            scale, basemap_url)
        end
      end

      context = {
        issue: @issue, other_attributes: @other_attributes, json: json
      }
      Redmine::Hook.call_hook(:redmine_gtt_print_issue_to_json, context)

      json.to_json
    end

    def attachments_datasource(attachments)
      return {
        title: "attachments",
        table: {
          columns: attachment_columns,
          data: attachments.where("filename ~* ?", '\.(jpg|jpeg|png|bmp|gif)$')
                  .map {|a| attachment_to_data_row a}
        }
      }
    end

    def attachment_columns
      columns = [
        "id",
        "filename",
        "filesize",
        "content_type",
        "description",
        "content_url",
        # "thumbnail_url",
        "author_id",
        "author_name",
        "created_on"
      ]
      if Redmine::Plugin.installed?(:redmine_attachment_categories)
        columns.push(
          "attachment_category_id",
          "attachment_category_name",
          "attachment_category_html_color"
        )
      end
      return columns
    end

    def attachment_to_data_row(attachment)
      data_row = [
        attachment.id,
        attachment.filename,
        attachment.filesize,
        attachment.content_type,
        attachment.description,
        download_named_attachment_url(attachment, attachment.filename, key: User.current.api_key),
        # attachment.thumbnailable? ? thumbnail_url(attachment) : nil,
        attachment.author&.id,
        attachment.author&.name,
        attachment.created_on
      ]
      if Redmine::Plugin.installed?(:redmine_attachment_categories)
        data_row.push(
          attachment.attachment_category&.id,
          attachment.attachment_category&.name,
          attachment.attachment_category&.html_color
        )
      end
      return data_row
    end

    def image_urls(attachments)
      if !Redmine::Plugin.installed?(:redmine_attachment_categories)
        default_image_urls = []
        attachments.map do |a|
          default_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
        end
        return {
          "default" => default_image_urls
        }
      else
        before_image_urls = []
        after_image_urls = []
        other_image_urls = []
        attachments.map do |a|
          if a.image?
            if a.attachment_category.nil?
              other_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
            elsif a.attachment_category.id == Setting.plugin_redmine_gtt_print['attachment_tag_before'].to_i
              before_image_urls.push(download_named_attachment_url(a, a.filename, key: User.current.api_key))
            elsif a.attachment_category.id == Setting.plugin_redmine_gtt_print['attachment_tag_after'].to_i
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
    end

    # the following static helpers are used by IssuesToJson as well

    def self.attributes_hash(issue, layout, other_attributes, attachments_datasource, image_urls)
      custom_fields = issue_custom_fields_by_name issue

      formatter = IssueFormatter.new(issue)

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
        is_private: formatter.is_private,
        is_public: formatter.is_public,
        start_date: formatter.start_date || "",
        done_date: formatter.closed_on || "",
        # due_date: issue.due_date,
        estimated_hours: formatter.estimated_hours || "",
        created_on: formatter.created_on || "",
        updated_on: formatter.updated_on || "",
        last_notes: issue.last_notes || "",
        all_notes: formatter.all_notes || "",

        # Custom text
        custom_text: other_attributes[:custom_text],

        # Experimental
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

        datasource: [
          attachments_datasource
        ]
      }

      # Image attachments (max. 4 iamges for each tags)
      if !Redmine::Plugin.installed?(:redmine_attachment_categories)
        result["image_url_1"] = image_urls["default"][0] || "../#{layout}/blank.png"
        result["image_url_2"] = image_urls["default"][1] || "../#{layout}/blank.png"
        result["image_url_3"] = image_urls["default"][2] || "../#{layout}/blank.png"
        result["image_url_4"] = image_urls["default"][3] || "../#{layout}/blank.png"
      else
        result["before_image_url_1"] = image_urls["before"][0] || "../#{layout}/blank.png"
        result["before_image_url_2"] = image_urls["before"][1] || "../#{layout}/blank.png"
        result["before_image_url_3"] = image_urls["before"][2] || "../#{layout}/blank.png"
        result["before_image_url_4"] = image_urls["before"][3] || "../#{layout}/blank.png"
        result["after_image_url_1"] = image_urls["after"][0] || "../#{layout}/blank.png"
        result["after_image_url_2"] = image_urls["after"][1] || "../#{layout}/blank.png"
        result["after_image_url_3"] = image_urls["after"][2] || "../#{layout}/blank.png"
        result["after_image_url_4"] = image_urls["after"][3] || "../#{layout}/blank.png"
        result["other_image_url_1"] = image_urls["other"][0] || "../#{layout}/blank.png"
        result["other_image_url_2"] = image_urls["other"][1] || "../#{layout}/blank.png"
        result["other_image_url_3"] = image_urls["other"][2] || "../#{layout}/blank.png"
        result["other_image_url_4"] = image_urls["other"][3] || "../#{layout}/blank.png"
      end

      custom_fields.each{|name, value| result["cf_#{name}"] = value || ""}

      result
    end

    def self.issue_custom_fields_by_name(issue)
      Hash[
        issue.visible_custom_field_values.map{|cfv|
          #puts "#{cfv.custom_field.name}: #{@@format_value_func.call(cfv.value, cfv.custom_field)}"
          [cfv.custom_field.name, RedmineGttPrint::CustomFieldFormatter.(cfv)]
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
