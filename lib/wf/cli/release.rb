module Wf
  module Cli
    # commands for release versions
    class Release < Thor
      desc 'hotfix <version> [comment]', 'Close hotfix/* branch'
      def hotfix(version, comment = nil)
        Structure.release_hotfix version, comment
      end

      desc 'close <version>', 'Close release/* branch'
      def close(version)
        Structure.release_close version
      end

      desc 'open <version>', 'Open release/* branch'
      def open(version)
        Structure.release_open version
      end
    end
  end
end
