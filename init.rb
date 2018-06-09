require 'redmine'

Rails.configuration.to_prepare do
  RedmineGttPrint.setup
end

Redmine::Plugin.register :redmine_gtt_print do
  name 'Redmine GTT Print Plugin'
  author 'Georepublic'
  author_url 'https://hub.georepublic.net/gtt/redmine_gtt_print'
  description 'Adds advanced printing capabilities for GTT reports'
  version '0.1.0'

  requires_redmine version_or_higher: '3.4.0'

  settings(
    default: {
      'default_print_server' => "http://localhost:8080/mfp"
    },
    partial: 'gtt_print/settings'
  )

  project_module :gtt_print do

    permission :view_gtt_print, {
      gtt_print_jobs: %i(create show)
    }, require: :member, read: true

  end

end
