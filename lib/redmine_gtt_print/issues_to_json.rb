# frozen_string_literal: true

module RedmineGttPrint

  # Transforms the given array of issues into JSON ready to be sent to the
  # mapfish print server
  #
  class IssuesToJson
    def initialize(issues, layout, other_attributes = {})
      @issues = issues
      @layout = layout
      @other_attributes = other_attributes
      @custom_fields_for_all = IssueCustomField.where(is_for_all: true).sort
    end

    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    def call
      columns = ["id", "status", "start_date", "created_on", "assigned_to_name", "subject", "description"]
      @custom_fields_for_all.map{|cf| columns.push("cf_#{cf.name}")}
      hsh = {
        layout: @layout,
        outputFilename: "DailyList",
        outputFormat: "pdf",
        attributes: {
          custom_text: @other_attributes[:custom_text],
          datasource: [
            {
              table: {
                columns: columns,
                data: @issues.map{|i| issue_to_data_row i}
              }
            }
          ]
        }
      }

      if (features = @issues.map(&:geodata_for_print).compact).any?
        # TODO determine a proper center for the whole set of features
        #center = features.first[:center]
        #hsh[:attributes][:map] = IssueToJson.map_data(
        #  center,
        #  features.map{|f| f[:geojson] }
        #)
      end

      context = {
        issues: @issues, other_attributes: @other_attributes, json: hsh
      }
      Redmine::Hook.call_hook(:redmine_gtt_print_issues_to_json, context)

      hsh.to_json
    end

    private

    def issue_to_data_row(i)
      columns = [
        i.id.to_s,
        i.status.name,
        i.start_date || "",
        i.created_on,
        i.assigned_to&.name || "",
        i.subject,
        i.description
      ]
      @custom_fields_for_all.map{|cf|
        cfv = i.visible_custom_field_values.find{|vcfv|
            vcfv.custom_field.name == cf.name
        }
        cfv.nil? ? columns.push("") : columns.push(cfv.value)
      }
      return columns
    end

  end
end

