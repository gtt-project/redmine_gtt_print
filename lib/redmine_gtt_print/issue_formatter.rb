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
  end
end