require File.expand_path('../lib/redmine_gtt_print/view_hooks', __FILE__)

if Rails.version > '6.0' && Rails.autoloaders.zeitwerk_enabled?
  Rails.application.config.after_initialize do
    RedmineGttPrint.setup
  end
else
  Rails.configuration.to_prepare do
    RedmineGttPrint.setup
  end
end

Redmine::Plugin.register :redmine_gtt_print do
  name 'Redmine GTT Print plugin'
  author 'Georepublic'
  author_url 'https://github.com/georepublic'
  url 'https://github.com/gtt-project/redmine_gtt_print'
  description 'Adds advanced printing capabilities for GTT reports'
  version '1.1.0'

  requires_redmine version_or_higher: '4.0.0'

  settings(
    default: {
      'default_print_server' => "http://localhost:8080",
      "tracker_config" => {},
      "issue_list_config" => nil,
      "default_print_server_timeout" => "5",
    },
    partial: 'gtt_print/settings'
  )

  project_module :gtt_print do

    permission :view_gtt_print, {
      gtt_print_jobs: %i(create show status)
    }, require: :member, read: true

  end

end
