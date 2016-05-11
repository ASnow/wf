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

        # парсинг вывода git комнад
        def exec_output_list(output)
          output.split("\n").map do |line|
            line.strip.sub('* ', '')
          end
        end

        def cherry(refspec)
          result = run 'cherry :refspec', with: { refspec: refspec }
          exec_output_list(result)
        end
      end
    end
  end
end
