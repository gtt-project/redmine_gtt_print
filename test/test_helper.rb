require File.expand_path(File.dirname(__FILE__) + '/../../redmine_gtt/test/test_helper')

class TestHookListener < Redmine::Hook::Listener
  def redmine_gtt_print_issue_to_json(context)
    context[:json][:issue_to_json_hook] = context[:issue].id
  end
  def redmine_gtt_print_issues_to_json(context)
    context[:json][:issues_to_json_hook] = context[:issues].size
  end
end

class TestMapfish
  attr_reader :issue, :layout
  def print_configs
    ['test-template']
  end

  def layouts(config)
    ['A4 portrait']
  end

  CreateJobResult = ImmutableStruct.new(:success?, :ref)
  PrintResult = ImmutableStruct.new(:pdf, :error)

  def initialize(is_sync = false)
    @ready_jobs = []
    @jobs = []
    @is_sync = is_sync
  end

  def is_sync?
    @is_sync
  end

  def printjob(name)
    @jobs << name
  end

  def printjob_ready(name)
    @ready_jobs << name
  end

  def print(job, referer = nil, user_agent = nil)
    @issue = job.issue
    @layout = job.layout

    if !@is_sync
      CreateJobResult.new(success: true, ref: 'some-job')
    else
      PrintResult.new(pdf: 'some-blob', error: nil)
    end
  end

  def get_status(ref)
    if @ready_jobs.include?(ref)
      :done
    elsif @jobs.include?(ref)
      :running
    else
      :not_found
    end
  end
end

