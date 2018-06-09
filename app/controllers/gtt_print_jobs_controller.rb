class GttPrintJobsController < ApplicationController
  layout 'base'

  before_action :find_optional_project
  before_action :authorize

  menu_item :issues

  def create
  end

  def show
  end
end
