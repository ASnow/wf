module Wf
  module Cli
    # commands for pull requests
    class PullRequest < Thor
      desc 'update <TASK> [base]', 'Merge base branch into TASK branch'
      def update(task, base = nil)
        Task.pr_update task, base
      end

      desc 'list', 'Print current open PR'
      def list
        Structure.pr_list
      end

      desc 'merge <PR_NUM>', 'Merge PR'
      def merge(number)
        Structure.pr_merge number
      end
    end
  end
end
