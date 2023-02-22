module RedmineGttPrint
  class IssueFormatter
    include ApplicationHelper
    include CustomFieldsHelper
    include Redmine::I18n
  
    def initialize(issue)
      @issue = issue
    end
  
    def is_private
      format_object @issue.is_private, false
    end

    def is_public
      format_object !@issue.is_private, false
    end

    def start_date
      format_object @issue.start_date, false
    end

    def created_on
      format_object @issue.created_on, false
    end

    def updated_on
      format_object @issue.updated_on, false
    end

    def closed_on
      format_object @issue.closed_on, false
    end

    def estimated_hours
      format_object @issue.estimated_hours, false
    end

    def all_notes
      joined_notes = ""
      @issue.journals.where.not(notes: [nil, ""]).each { |journal|
        if joined_notes.present?
          joined_notes += "\r\n\r\n"
        end
        joined_notes += format_object(journal.created_on, false) + "\r\n" + journal.notes
      }
      return joined_notes
    end
  end
end