class GttPrintJobsController < ApplicationController
  layout 'base'

  before_action :find_optional_project
  before_action :find_issues, only: :create

  before_action :authorize_create, only: :create
  before_action :authorize_global, except: :create

  menu_item :issues

  def create
    if (layout = params[:gtt_print_layout]).present?
      if @issue
        @result = RedmineGttPrint.mapfish.print_issue @issue, layout
      elsif @issues
        @result = RedmineGttPrint.mapfish.print_issues @issues, layout
      end
      render status: (@result&.success? ? :created : 422)
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
      send_data pdf, filename: "report.pdf", type: 'application/pdf'
    else
      render text: r.error, status: 500
    end
  end

  private

  def authorize_create
    if @project
      authorize
    else
      authorize_global
    end
  end

  def find_issues
    if params[:issue_id]
      @issue = (@project ? @project.issues : Issue).visible.find params[:issue_id]
    elsif params[:issue_ids]
      @issues = Issue.visible.where(id: params[:issue_ids].split(','))
    end
    @project ||= @issue.project if @issue
  end

end
