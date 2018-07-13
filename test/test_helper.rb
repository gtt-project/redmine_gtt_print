require File.expand_path(File.dirname(__FILE__) + '/../../redmine_gtt/test/test_helper')

class TestMapfish
  attr_reader :issue, :layout
  def print_configs
    ['test-template']
  end

  def layouts(config)
    ['A4 portrait']
  end

  Result = ImmutableStruct.new(:success?, :ref)

  def initialize
    @ready_jobs = []
    @jobs = []
  end

  def printjob(name)
    @jobs << name
  end

  def printjob_ready(name)
    @ready_jobs << name
  end

  def print(job)
    @issue = job.issue
    @layout = job.layout

    Result.new(success: true, ref: 'some-job')
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

