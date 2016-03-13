module Wf
  # Gitflow implementation
  class Task
    class << self
      include Wrapper::Logger
      include Wrapper::Cmd

      def start(task, base)
        log "FOR TASK #{task}:"
        target_branch = Structure.extract_target_param! base
        push
        switch_to_task task, target_branch
      end

      def push(comment = nil, status = ask_phase)
        return unless in_wf_branch

        log "Current task: #{env_task}"
        git.protect_changes(comment, "#{env_task} #{status} ")
        push_task env_task
      end

      def update
        return unless in_wf_branch
        git.pull Structure.ask_target_branch
        pull_task env_task
      end

      def close(base)
        target_branch = Structure.extract_target_param! base
        push nil, '#resolve-issue'
        if Wrapper::Github.hub_check?
          Wrapper::Github.create_pull_request "#{env_task} close", target_branch
        elsif boolean_ask("Hub don't installed.\nCommit direct to #{target_branch}?")
          git.switch_to target_branch
          pull_task env_task
          git.push
        end
        self.env_task = nil
      end

      def pr_update(task, base)
        git.in_branch(local(task)) do
          target_branch = Structure.extract_target_param! base
          git.with_merged target_branch do
            `rake db:migrate` if boolean_ask 'Update schema?'
            git.push remote task
          end
        end
      end

      def exit
        self.env_task = nil
        git.switch_to Structure.ask_target_branch
      end

      def env_task
        JSON.load(File.read('.wf'))
      rescue
        nil
      end

      protected

      def git
        Wrapper::Git
      end

      PHASES = { 's' => '#stop-progress', 'r' => '#resolve-issue' }.freeze
      def ask_phase
        return unless in_wf_branch
        log "You are leaving #{env_task}"
        answer = ask_for_valid('What is state of the task?', 's - stop, r - resolve', /\As|r\z/)
        PHASES[answer]
      end

      def switch_to_task(task, start_point = :master)
        git.switch_to local(task), start_point
        self.env_task = task
      end

      def env_task=(task)
        File.write('.wf', JSON.dump(task))
      end

      def push_task(task)
        git.push %(#{remote(task)}:#{local(task)})
      end

      def local(feature)
        Structure.local_feature_branch(feature)
      end

      def remote(feature)
        Structure.remote_feature_branch(feature)
      end

      def pull_task(task)
        git.pull Structure.remote_feature_branch task
      end

      def in_wf_branch
        env_task && git.current_branch == local(env_task)
      end

      # def commit?(args)
      #   params_to_commit?(args) || ask_to_commit
      # end

      # def params_to_commit?(args)
      #   %w(c commit).include? args[0]
      # end
    end
  end
end
