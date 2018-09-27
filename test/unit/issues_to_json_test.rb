require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class IssuesToJsonTest < ActiveSupport::TestCase
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
    @issues = Issue.find(1, 2)
    @issues.first.update_attribute :geojson, test_geojson
  end

  test 'should build mapfish json' do
    assert j = RedmineGttPrint::IssuesToJson.(@issues, 'das layout')
    assert h = JSON.parse(j)
    assert_equal 'das layout', h['layout']
    assert table = h['attributes']['datasource'][0]['table']['data']
    assert_equal @issues[0].subject, table[0].last
    assert_equal @issues[1].subject, table[1].last
  end

  test 'should include map json in attributes' do
    skip 'removed for now'
    assert j = RedmineGttPrint::IssuesToJson.(@issues, 'das layout')
    assert h = JSON.parse(j)
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

end


