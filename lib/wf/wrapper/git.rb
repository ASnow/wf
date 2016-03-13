module Wf
  module Wrapper
    class Git
      class << self
        include Cmd
        include Logger

        def run *args
          args.unshift 'git' unless args.first.is_a? Cocaine::CommandLine
          super *args
        end
        def status
          run('status -b -s').split("\n")
        end

        def current_branch
          run('rev-parse --abbrev-ref HEAD').split("\n")[0]
        end

        def branch?(name)
          run('branch --list :name', with: {name: name}).size > 0
        end

        def merge! branch
          run 'merge :branch --no-edit', with: {branch: branch}
          true
        rescue Cocaine::ExitStatusError => e
          false
        end

        def with_stash
          if uncommited?
            run('stash')
            yield
            run('stash pop')
          else
            yield
          end
        end

        def in_branch(branch)
          return_to = current_branch
          return yield if return_to == branch

          with_stash do
            switch_to branch
            yield
            switch_to return_to
          end
        end

        def with_merged(branch)
          msg = "Merge branch #{branch} into #{current_branch}"
          log msg
          commit! get_comment(nil, msg) while !merge!(branch)
          yield
        end

        def uncommited?
          status.size > 1
        end

        def check_conflicts!
          loop do
            conflicts = run "diff --name-only --diff-filter=U"
            return if conflicts == ''
            log "Resolve conflicts and continue?\n#{conflicts}"
            answer = ask_for_valid "Press Continue then finish?", "(C)", /c(ontinue)?/i
          end
        end

        def commit!(msg)
          log "Current task: #{env_task}" if env_task
          check_conflicts!
          run_cops
          run "add ."
          run "commit -a -m :message", with: {message: msg}
        end

        def ask_to_commit
          log "Changes"
          puts status[1..-1].join("\n")
          boolean_ask "Commit?"
        end

        def changed_files
          status[1..-1].map { |line| line[3..-1] }
        end

        def ruby_changed_files
          changed_files.select { |path| path =~ /(\.rb|\.rake)\z/i }
        end

        def pull(remote_branch = current_branch)
          result = nil
          cmd = run "pull origin :branch", return: :cmd

          loop do
            commit! get_comment if uncommited? && ask_to_commit
            with_stash do
              log cmd.command branch: remote_branch
              result = run cmd, with: {branch: remote_branch}, return: :bool
            end
            return if result || cmd.command_error_output =~ /Couldn't find remote ref/
          end
        end

        def push refspec
          run "push origin :refspec", with: {refspec: refspec}
        end

        def branch_subtree_for(prefix)
          result = run 'branch -a --list :mask', with: {mask: "#{prefix}/*"}
          branch_subtree = exec_output_list result
          
          branch_subtree.sort_by { |a| a.split('/').last.split('.').map(&:to_i) }
        end    

        # парсинг вывода git комнад
        def exec_output_list(output)
          output.split("\n").map do |line| 
            line.strip.sub('* ', '')
          end
        end

        def switch_to(branch, start_point = nil, opts = nil)
          unless branch?(branch)
            start_point = current_branch unless start_point
            in_branch start_point do
              __switch_to branch, "#{opts} -b "
            end
          end
          __switch_to branch, opts
          log "Current branch: #{branch}"
        end

        def __switch_to(branch, opts = nil)
          while !run("checkout #{opts} :branch", with: {branch: branch}, return: :bool)
            log "Can't switch branch to #{branch} untill changes apply:"
            puts status[1..-1].join("\n")
            log "Please fix you changes and do next:"
            answer = ask_for_valid "commit or stash changes?", "(c/s)", /c(ommit)?|s(tash)?/i
            if answer =~ /c(ommit)?/i
              commit! get_comment
            else
              `git stash`
            end
          end
          pull branch
        end


        def get_comment(args = nil, prefix = '')
          "#{prefix}#{args || ask_comment(prefix)}"
        end

        def ask_comment(prefix = '')
          log "Comment for commit: #{prefix}"
          $stdin.gets
        end
      end
    end
  end
end
