module Wf
  module Wrapper
    class Rubocop
      class << self
        include Logger

        RES_PARSE_RE = /(?<offenses>\d+|no) offenses? detected(, (?<corrections>\d+|no) offenses? corrected)?/i

        def run files
          if files.empty?
            true
          else
            loop do
              log "Run cops"
              res = Cmd.run 'rubocop', '-a -R :files', with: {files: files}
              log res
              state = RES_PARSE_RE.match(res)
              if state[:offenses].to_i == state[:corrections].to_i
                break
              else
                log "Cops fails!!!\n Press enter to continue."
                $stdin.gets
              end
            end
          end
        end
      end
    end
  end
end
