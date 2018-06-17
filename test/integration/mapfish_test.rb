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
    @mapfish = RedmineGttPrint::Mapfish.new host: "https://print.***REMOVED***"
  end


  test "should have templates" do
    assert templates = @mapfish.templates
    assert_equal Array, templates.class
    assert templates.include?("default")
  end

  test "should get status" do
    assert_equal :not_found, @mapfish.get_status("bogus")
  end

  test "should issue print job" do
    i = Issue.find 1
    i.update_attribute :geojson, test_geojson

    assert r = @mapfish.print_issue(i, 'DEMO_gtt')
    assert r.success?
    assert ref = r.ref
    sleep 2
    assert_equal :done, @mapfish.get_status(ref)
    assert pdf = @mapfish.get_print(ref)
    (File.open('print.pdf', 'wb') << pdf).close
  end

end
