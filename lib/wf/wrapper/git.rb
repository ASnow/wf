module Wf
  module Wrapper
    # Wrapper for git
    class Git
      class << self
        include Logger
        include Basic
        include Switch
        include Branch

        def index
          selected = draw_checkboxes changed_files
          return if selected.empty?
          run 'add :files', with: { files: selected }
        end

        def with_stash
          if uncommited?
            run('stash')
            yield
            check_conflicts!
            check_conflicts! unless run('stash pop', return: :bool)
          else
            yield
          end
        end

        def with_merged(branch)
          msg = "Merge branch #{branch} into #{current_branch}"
          log msg
          commit! get_comment(nil, msg) until merge!(branch)
          yield
        end

        def uncommited?
          status.size > 1
        end

        def check_conflicts!
          loop do
            conflicts = run 'diff --name-only --diff-filter=U'
            return if conflicts == ''
            log "Resolve conflicts and continue?\n#{conflicts}"
            ask_for_valid 'Press Continue then finish?', '(C)', /c(ontinue)?/i
          end
        end

        def check_style(files = ruby_changed_files)
          Rubocop.run files
        end

        def ask_to_commit
          log 'Changes'
          puts status[1..-1].join("\n")
          boolean_ask 'Commit?'
        end

        def changed_files
          status[1..-1].map { |line| line[3..-1] }
        end

        def ruby_changed_files
          changed_files.select { |path| path =~ /(\.rb|\.rake)\z/i }
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
