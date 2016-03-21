module Wf
  module Cli
    # commands for release versions
    class Deploy < Thor
      desc 'remote', 'Deploy to production server'
      def remote
        Wf::Deploy.deploy
      end

      desc 'local', 'Deploy localy. Get all changes from git'
      def local
        Wf::Deploy.deploy_local
      end
    end
  end
end
