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
    assert j = RedmineGttPrint::IssueToJson.(@issue, 'das layout')
    assert h = JSON.parse(j)
    assert_equal 'das layout', h['layout']
    assert_equal @issue.subject, h['attributes']['subject']
    assert map = h['attributes']['map']
    assert_equal 2, map['center'].size
    assert geo = map['layers'][0]['geoJson']
    assert_equal 'FeatureCollection', geo['type']
    assert feature = geo['features'][0]
    assert_equal 'Feature', feature['type']
    assert geom = feature['geometry']
    assert_equal 'Polygon', geom['type']
    assert_equal 15052703.2783315, geom['coordinates'].flatten.first
  end

  test 'should handle issue without geometry' do
    i = Issue.find(2)
    assert j = RedmineGttPrint::IssueToJson.(i, 'layout')
    assert h = JSON.parse(j)
    assert_equal i.subject, h['attributes']['subject']
    assert_nil h['attributes']['map']
  end


end

