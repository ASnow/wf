module Wf
  module Wrapper
    # wrapper for rubocop gem
    class Rubocop
      class << self
        include Logger

        RES_PARSE_RE = /(?<offenses>\d+|no) offenses? detected(, (?<corrections>\d+|no) offenses? corrected)?/ix

        def run(files)
          if files.empty?
            true
          else
            fix_cops files
          end
        end

        def fix_cops(files)
          loop do
            log 'Run cops'
            res = Cmd.run 'rubocop', '-a -R :files', with: { files: files }, return: :bool
            break if res

            log "Cops fails!!!\n Press enter to continue."
            $stdin.gets
          end
        end

        # old check
        # state = RES_PARSE_RE.match(res)
        # || state[:offenses].to_i == state[:corrections].to_i
      end
    end
  end
end
