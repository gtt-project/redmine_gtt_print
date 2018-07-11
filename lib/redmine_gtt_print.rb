require 'redmine_gtt_print/view_hooks'

module RedmineGttPrint
  def self.setup
  end

  def self.settings
    Setting.plugin_redmine_gtt_print
  end

  def self.tracker_config(tracker)
    (settings['tracker_config'] || {})[tracker.id.to_s]
  end

  def self.mapfish
    RequestStore.store[:mapfish] ||=
      RedmineGttPrint::Mapfish.new(host: settings['default_print_server'])
  end


end
