require_relative '../test_helper'

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
           :issue_categories,
           :issues,
           :enumerations,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers,
           :attachments

  def setup
    super
    User.current = nil
    Role.find(1).add_permission! :view_gtt_print
    @project = Project.find 'ecookbook'
    @issue = @project.issues.first
    EnabledModule.create! project: @project, name: 'gtt_print'

    Setting.plugin_redmine_gtt_print['enable_sync_printing'] = false
    @mapfish = TestMapfishAsync.new
    RedmineGttPrint.stubs(:mapfish).returns @mapfish
  end


  def test_should_create_print_job
    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_job_layout option', text: "A4 portrait", count: 0

    log_user 'jsmith', 'jsmith'
    get '/projects/ecookbook/issues/new'
    assert_response :success

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_job_layout option', text: "A4 portrait"

    post "/gtt_print_jobs", xhr: true, params: { issue_id: @issue.id,
                                    gtt_print_job: { layout: "A4 portrait" } }
    assert_response :created

    assert_equal @issue, @mapfish.issue
    assert_equal 'A4 portrait', @mapfish.layout
  end

  def test_should_create_print_job_sync
    Setting.plugin_redmine_gtt_print['enable_sync_printing'] = 'true'
    @mapfish = TestMapfishSync.new
    RedmineGttPrint.stubs(:mapfish).returns @mapfish

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_job_layout option', text: "A4 portrait", count: 0

    log_user 'jsmith', 'jsmith'
    get '/projects/ecookbook/issues/new'
    assert_response :success

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select '#gtt_print_job_layout option', text: "A4 portrait"

    post "/gtt_print_jobs", params: { issue_id: @issue.id,
                                    gtt_print_job: { layout: "A4 portrait" } }
    assert_response :success

    assert_equal @issue, @mapfish.issue
    assert_equal 'A4 portrait', @mapfish.layout
  end

  def test_should_check_job_status
    @mapfish.printjob 'running-job'
    @mapfish.printjob_ready 'finished-job'
    log_user 'jsmith', 'jsmith'

    get "/gtt_print_jobs/bogus/status", params: { project_id: 'ecookbook'}
    assert_response :not_found

    get "/gtt_print_jobs/running-job/status", params: { project_id: 'ecookbook'}
    assert_response :success
    json = JSON.parse response.body
    assert_equal 'running', json['status']

    get "/gtt_print_jobs/finished-job/status", params: { project_id: 'ecookbook'}
    assert_response :success
    json = JSON.parse response.body
    assert_equal 'done', json['status']
  end

end

