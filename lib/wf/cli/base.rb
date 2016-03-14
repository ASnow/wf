
module Wf
  module Cli
    # bin CLI base comads
    class Base < Thor
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

      desc 'deploy SUBCOMMAND ...ARGS', 'deploy project'
      subcommand 'deploy', Deploy

      desc 'pr SUBCOMMAND ...ARGS', 'manage pull requests'
      subcommand 'pr', PullRequest

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

      desc 'pull', 'Git pull with stash or commit'
      def pull
        Wrapper::Git.pull
      end

      desc 'check', 'Check style guide'
      option :all, type: :boolean
      def check
        if options[:all]
          Wrapper::Rubocop.run '.'
        else
          Wrapper::Git.check_style
        end
      end

      desc 'install', ''
      def install
        Install.install
      end

      desc 'tree_update', 'Update git tree by priority [hotfix, release, master]'
      def tree_update
        Structure.tree_update
      end
    end
  end
end
