require 'redmine'

Redmine::Plugin.register :redmine_gtt_print do
  name 'Redmine GTT Print Plugin'
  author 'Georepublic'
  author_url 'https://hub.georepublic.net/gtt/redmine_gtt_print'
  description 'Adds advanced printing capabilities for GTT reports'
  version '0.1.0'

  requires_redmine version_or_higher: '3.4.0'
end

