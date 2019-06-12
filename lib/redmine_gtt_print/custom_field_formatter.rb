module RedmineGttPrint
  class CustomFieldFormatter
    include ApplicationHelper
    include CustomFieldsHelper
    include Redmine::I18n
  
    def initialize(custom_field_value)
      @cfv= custom_field_value
    end
  
    def value
      format_value @cfv.value, @cfv.custom_field
    end
    
    # This adds some syntactic sugar as it allows to use this class like this:
    # CustomFieldFormatter.(custom_field_value)
    def self.call(custom_field_value)
      new(custom_field_value).value
    end
  end
end