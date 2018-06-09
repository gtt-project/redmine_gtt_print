require_relative '../test_helper'

class TestMapfish
  def templates
    ['test-template']
  end
end

class IssuePrintTest < Redmine::IntegrationTest
  fixtures :projects,
           :users, :email_addresses,
           :roles,
           :members,
           :member_roles,
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

  def setup
    super
    User.current = nil
    @project = Project.find 'ecookbook'
    @issue = @project.issues.first
    EnabledModule.create! project: @project, name: 'gtt_print'
    Role.find(1).add_permission! :view_gtt_print
  end


  def test_should_create_print_job

    RedmineGttPrint.stubs(:mapfish).returns TestMapfish.new
    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_template option', text: "test-template", count: 0

    log_user 'jsmith', 'jsmith'
    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_template option', text: "test-template"
  end

end
