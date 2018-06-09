class MapfishTest < ActionDispatch::IntegrationTest
  setup do
    @mapfish = RedmineGttPrint::Mapfish.new host: "https://print.***REMOVED***"
  end


  test "should have templates" do
    assert templates = @mapfish.templates
    assert_equal Array, templates.class
    assert templates.include?("default")
  end

end
