require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class IssueToJsonTest < ActiveSupport::TestCase
  include GttTestData

  fixtures :projects,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :issue_statuses,
           :issues,
           :enumerations,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers,
           :attachments

  setup do
    @issue = Issue.find 1
    @issue.update_attribute :geojson, test_geojson
  end

  test 'should build mapfish json' do
    assert j = RedmineGttPrint::IssueToJson.(@issue)
    assert h = JSON.parse(j)
    assert_equal @issue.subject, h['attributes']['title']
    assert map = h['attributes']['map']
    assert_equal 2, map['center'].size
    assert geo = map['layers'][0]['geoJson']
    assert_equal 'Feature', geo['type']
    assert geom = geo['geometry']
    assert_equal 'Polygon', geom['type']
    assert_equal 15052703.2783315, geom['coordinates'].flatten.first
  end

  test 'should handle issue without geometry' do
    i = Issue.find(2)
    assert j = RedmineGttPrint::IssueToJson.(i)
    assert h = JSON.parse(j)
    assert_equal i.subject, h['attributes']['title']
    assert_nil h['attributes']['map']
  end


end

