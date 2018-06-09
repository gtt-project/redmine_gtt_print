class MapfishTest < ActionDispatch::IntegrationTest
  setup do
    @mapfish = RedmineGttPrint::Mapfish.new host: "https://print.mycityreport.jp"
  end


  test "should have templates" do
    assert templates = @mapfish.templates
    assert_equal Array, templates.class
    assert templates.include?("default")
  end

end
