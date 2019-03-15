require 'redmine_gtt_print/view_hooks'

module RedmineGttPrint
  def self.setup
  end

  def self.settings
    Setting.plugin_redmine_gtt_print
  end

  def self.list_config
    settings['issue_list_config']
  end

  def self.list_layouts
    if cfg = list_config
      mapfish.layouts cfg
    end
  end

  def self.tracker_config(tracker)
    (settings['tracker_config'] || {})[tracker.id.to_s]
  end

  def self.layouts_for_tracker(tracker)
    mapfish.layouts tracker_config tracker
  end

  def self.mapfish
    RequestStore.store[:mapfish] ||=
      RedmineGttPrint::Mapfish.new(host: settings['default_print_server'])
  end


end
