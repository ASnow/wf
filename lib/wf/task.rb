module Wf
  class Task
    class << self
      include Wrapper::Logger
      include Wrapper::Cmd

      # ok
      def start(task, base)
        log "FOR TASK #{task}:"
        target_branch = Structure.extract_target_param! base
        push
        switch_to_task task, target_branch
      end

      # ok
      def push(comment = nil, status = set_phase)
        if in_wf_branch
          if git.uncommited? && git.ask_to_commit
            git.commit! git.get_comment(comment, "#{env_task} #{status} ")
          end
          push_task env_task
        end
      end

      # ok
      def update
        if in_wf_branch
          git.pull Structure.ask_target_branch
          pull_task env_task
        end
      end

      # ok
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
        set_env_task nil
      end

      # ok
      def pr_update(task, base)
        git.in_branch(local(task)) do
          target_branch = Structure.extract_target_param! base
          git.with_merged target_branch do
            `rake db:migrate` if boolean_ask 'Update schema?'
            git.push remote task
          end
        end
      end

      # ok
      def exit
        set_env_task nil
        git.switch_to Structure.ask_target_branch
      end

      # ok
      def env_task
        JSON.load(File.read('.wf'))
      rescue
        nil
      end

      protected

      def git
        Wrapper::Git
      end

      # ok
      def set_phase
        if in_wf_branch
          log "You are leaving #{env_task}"
          state = nil
          until state
            log 'What is state of the task? (s/r/?)'
            state = case $stdin.gets
                    when /s/ then
                      '#stop-progress'
                    when /r/ then
                      '#resolve-issue'
                    else
                      log 'Choose next one: s - stop, r - resolve'
                      nil
                    end
          end
          state
        end
      end

      # ok
      def switch_to_task(task, start_point = :master)
        git.switch_to local(task), start_point
        pull_task task
        set_env_task task
      end

      # ok
      def set_env_task(task)
        File.write('.wf', JSON.dump(task))
      end

      # ok
      def push_task(task)
        git.push %("#{remote(task)}":"#{local(task)}")
      end

      # ok
      def local(feature)
        Structure.local_feature_branch(feature)
      end

      # ok
      def remote(feature)
        Structure.remote_feature_branch(feature)
      end

      # ok
      def pull_task(task)
        git.pull Structure.remote_feature_branch task
      end

      # ok
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
