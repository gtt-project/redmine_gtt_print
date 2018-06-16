class GttPrintJobsController < ApplicationController
  layout 'base'

  before_action :find_optional_project
  before_action :find_issue, only: :create

  before_action :authorize, only: :create
  before_action :authorize_global, except: :create

  menu_item :issues

  def create
    if @issue and (template = params[:gtt_print_template]).present?
      @result = RedmineGttPrint.mapfish.print_issue @issue, template
      render status: (@result.success? ? :created : 422)
    else
      render_404
    end
  end

  def status
    status = RedmineGttPrint.mapfish.get_status(params[:id])
    case status
    when :done
      render json: { status: 'done', path: gtt_print_job_path(params[:id]) }
    when :not_found
      render nothing: true, status: :not_found
    else
      render json: { status: 'running' }
    end
  end

  def show
    r = RedmineGttPrint.mapfish.get_print params[:id]
    if pdf = r.pdf
      send_data pdf
    else
      render text: r.error, status: 500
    end
  end

  private

  def find_issue
    if params[:issue_id]
      @issue = (@project ? @project.issues : Issue).visible.find params[:issue_id]
    end
    @project ||= @issue.project if @issue
  end

end
