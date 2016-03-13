require 'thor'
require_relative '../wf'
require_relative 'cli/release'

module Wf
  # bin CLI
  class Cli < Thor
    desc 'start <TASK> [base]', 'Switch current work space to new TASK. New branch based on BASE branch. BASE can be: m(aster), h(otfix).'
    def start(task, base = nil)
      Task.start task, base
    end

    desc 'switch <TASK> [base]', 'Same as start'
    def switch(task, base = nil)
      Task.start task, base
    end

    desc 'release SUBCOMMAND ...ARGS', 'manage relese for versions'
    subcommand 'release', Release

    desc 'push [comment] [status]', 'Save current TASK state to remote branch. Default status #in-progress'
    def push(comment = nil, status = '#in-progress')
      Task.push comment, status
    end

    desc 'update', 'Pull from remote base and TASK branch'
    def update
      Task.update
    end

    desc 'close [base]', 'Push to remote branch and create PR to base branch. Or push to base branch. Check rubocop'
    def close(base = nil)
      Task.close base
    end

    desc 'exit', 'Remove TASK variable'
    def exit
      Task.exit
    end

    desc 'pr_update <TASK> [base]', 'Merge base branch into TASK branch'
    def pr_update(task, base = nil)
      Task.pr_update task, base
    end

    desc 'pull', ''
    def pull
      Wrapper::Git.pull
    end

    desc 'run_cops', ''
    option :all, type: :boolean
    def run_cops
      if options[:all]
        Wrapper::Rubocop.run '.'
      else
        Wrapper::Git.check_style
      end
    end

    desc 'test ...ARGS', ''
    def test(*args)
      # WF.test ARGV[1..-1]
    end

    desc 'install', ''
    def install
      WF.install
    end

    desc 'deploy', 'Deploy to production server'
    def deploy
      WF.deploy
    end

    desc 'deploy_local', 'Deploy localy. Get all changes from git'
    def deploy_local
      WF.deploy_local
    end

    desc 'tree_update', 'Update git tree by priority [hotfix, release, master]'
    def tree_update
      WF.tree_update
    end

    desc 'pr_list', 'Print current open PR'
    def pr_list
      WF.pr_list
    end

    desc 'pr_merge ...ARGS', ''
    def pr_merge
      WF.pr_merge ARGV[1..-1]
    end

    OLD_HELP = <<-HELP.freeze
      Workflow helper
        Commands:
          start JIRA_TASK [(m)aster|(h)otfix]
          switch JIRA_TASK [(m)aster|(h)otfix] # same as start
          push
          close [(m)aster|(h)otfix]
          release [open|close|hotfix] VERSION
        All commands takes options after command:
          [(c)ommit ["comment"]]
            commit - auto commit
            comment - comment for commit
    HELP
    desc 'old_help', 'Print old help'
    def old_help
      puts <<-HELP
      Current task: #{Task.env_task}
      #{OLD_HELP}
      HELP
    end
  end
end
