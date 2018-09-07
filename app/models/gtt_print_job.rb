# frozen_string_literal: true

class GttPrintJob
  include ActiveModel::Model

  attr_accessor :layout, :custom_text, :issue, :issues, :scale, :basemap_url

  validates :layout, presence: true
  validates :issue, presence: true,  if: ->{ issues.nil? }
  validates :issues, presence: true, if: ->{ issue.nil? }

  def list?
    issue.nil? && issues.present?
  end

  def json
    if list?
      RedmineGttPrint::IssuesToJson.(issues, layout, custom_text: custom_text)
    else
      RedmineGttPrint::IssueToJson.(issue, layout, { custom_text: custom_text,
        scale: scale, basemap_url: basemap_url })
    end
  end

  def print_config
    if list?
      RedmineGttPrint.list_config
    else
      RedmineGttPrint.tracker_config(issue.tracker)
    end
  end

  def format
    "pdf"
  end
end
