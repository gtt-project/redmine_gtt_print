require_relative '../test_helper'

class MapfishTest < ActionDispatch::IntegrationTest
  include GttTestData

  fixtures :projects,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :issue_statuses,
           :issues,
           :enumerations

  setup do
    @issue = Issue.find 1
    @mapfish = RedmineGttPrint::Mapfish.new host: "https://print.mycityreport.jp"
    Setting.plugin_redmine_gtt_print = {'tracker_config' => { @issue.tracker.id.to_s => 'default' }}
  end

  test "should have print configs" do
    assert configs = @mapfish.print_configs
    assert_equal Array, configs.class
    assert configs.include?("default")
  end

  test "should handle nil print config" do
    assert_equal [], @mapfish.layouts(nil)
  end

  test "should have layouts for print config" do
    assert layouts = @mapfish.layouts("default")
    assert_equal Array, layouts.class
    assert layouts.include?("default"), layouts.inspect
  end

  test "should get status" do
    assert_equal :not_found, @mapfish.get_status("bogus")
  end

  test "should issue print job" do
    i = @issue
    i.update_attribute :geojson, test_geojson
    job = GttPrintJob.new issue: i, layout: 'default'

    assert r = @mapfish.print(job)
    assert r.success?
    assert ref = r.ref
    status = nil
    loop do
      status = @mapfish.get_status(ref)
      break if status == :done
      assert_equal :running, status
      sleep 2
    end
    assert_equal :done, status
    assert pdf = @mapfish.get_print(ref)
    (File.open('print.pdf', 'wb') << pdf).close
  end

end
