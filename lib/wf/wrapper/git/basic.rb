module Wf
  module Wrapper
    class Git
      # git basic commands
      module Basic
        include Cmd

        def run(*args)
          args.unshift 'git' unless args.first.is_a? Cocaine::CommandLine
          super(*args)
        end

        def status
          run('status -b -s').split("\n")
        end

        def branch?(name)
          !run('branch --list :name', with: { name: name }).empty?
        end

        def merge!(branch)
          run 'merge :branch --no-edit', with: { branch: branch }
          true
        rescue Cocaine::ExitStatusError
          false
        end

        def commit!(msg)
          check_conflicts!
          check_style
          run 'add .'
          run 'commit -a -m :message', with: { message: msg }
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
          __switch_loop branch, opts
          pull branch
        end

        def __switch_loop(branch, opts)
          checkout = run("checkout #{opts} :branch", with: { branch: branch }, return: :bool)
          until checkout
            log "Can't switch branch to #{branch} untill changes apply:"
            puts status[1..-1].join("\n")
            log 'Please fix you changes before next:'
            protect_changes do
              checkout = run("checkout #{opts} :branch", with: { branch: branch }, return: :bool)
            end
          end
        end

        def pull(remote_branch = current_branch)
          result = nil
          cmd = run 'pull origin :branch', return: :cmd

          loop do
            protect_changes do
              log cmd.command branch: remote_branch
              result = run cmd, with: { branch: remote_branch }, return: :bool
            end
            return if result || cmd.command_error_output =~ /Couldn't find remote ref/
          end
        end

        def protect_changes(comment = nil, prefix = nil)
          commit! get_comment(comment, prefix) if uncommited? && ask_to_commit
          with_stash do
            yield if block_given?
          end
        end

        def push(refspec)
          run 'push origin :refspec', with: { refspec: refspec }
        end
      end
    end
  end
end
