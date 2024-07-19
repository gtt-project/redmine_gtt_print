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

  def initialize()
    @ready_jobs = []
    @jobs = []
  end

  def printjob(name)
    @jobs << name
  end

  def printjob_ready(name)
    @ready_jobs << name
  end

  def print(job, referer = nil, user_agent = nil)
    raise NotImplementedError
  end

  def get_status(ref)
    raise NotImplementedError
  end
end

class TestMapfishAsync < TestMapfish
  CreateJobResult = ImmutableStruct.new(:success?, :ref)
  PrintResult = ImmutableStruct.new(:pdf, :error)

  def print(job, referer = nil, user_agent = nil)
    @issue = job.issue
    @layout = job.layout

    CreateJobResult.new(success: true, ref: 'some-job')
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

class TestMapfishSync < TestMapfish
  CreateJobResult = ImmutableStruct.new(:success?, :ref)
  PrintResult = ImmutableStruct.new(:pdf, :error)

  def print(job, referer = nil, user_agent = nil)
    @issue = job.issue
    @layout = job.layout

    PrintResult.new(pdf: 'some-blob', error: nil)
  end

  def get_status(ref)
    error_msg = "get_status is not supported in sync mode"
    Rails.logger.error error_msg
    return PrintResult.new error: error_msg
  end
end
