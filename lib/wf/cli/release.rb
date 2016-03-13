module Wf
  class Cli < Thor
    class Release < Thor

      desc "hotfix ...ARGS", "Close hotfix/* branch"
      def hotfix *args
        WF.release_hotfix args
      end

      desc "close ...ARGS", "Close release/* branch"
      def close *args
        WF.release_close args
      end

      desc "open ...ARGS", "Open release/* branch"
      def open *args
        WF.release_open args
      end
      
    end
  end
end
