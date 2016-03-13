module Wf
  class Install
    def self.install
      log 'Install for linux-amd64'
      `mkdir tmp`
      Dir.chdir('tmp') do
        `wget https://github.com/github/hub/releases/download/v2.2.1/hub-linux-amd64-2.2.1.tar.gz`
        `tar -xzf hub-linux-amd64-2.2.1.tar.gz`
        `rm hub-linux-amd64-2.2.1.tar.gz`
        Dir.chdir('hub-linux-amd64-2.2.1') do
          log 'sudo cp hub /usr/local/bin/hub'
          `sudo cp hub /usr/local/bin/hub`
        end
      end
    end
  end
end
