module Wf
  # project deploys
  class Deploy
    class << self
      include Wrapper::Cmd
      SERVERS_FILE = '.wf_servers'.freeze
      include SSHKit::DSL

      def deploy
        current_server = ask_for_server
        password = current_server['password']

        host = SSHKit::Host.new("#{current_server['user']}@#{current_server['host']}")
        host.port = current_server['port'] || 22
        host.password = password
        on host do
          as :bckp_usr do
            within('/home/bckp_usr') { execute('~/backup.sh') }
          end
          as :rubyuser do
            within(current_server['working_dir']) do
              execute('ruby wf deploy_local')
              execute('touch tmp/restart.txt')
            end
          end
        end
      end

      def deploy_local
        log 'Deploy local'
        prev_commit = `git rev-parse HEAD`.chomp
        log 'git pull...'
        git.pull
        files = `git diff --name-only #{prev_commit}`.split($INPUT_RECORD_SEPARATOR)
        log 'bundle install...'
        `bundle install --without=development test` if files.any? { |f| f =~ /Gemfile(\.lock)?/ }
        log 'rake db:migrate...'
        `rake db:migrate RAILS_ENV=production` if files.any? { |f| f =~ %r{db/migrate/.*\.rb} }
        log 'localeapp pull...'
        `localeapp pull`
        log 'rake assets:precompile...'
        `rake assets:precompile RAILS_ENV=production` if files.any? { |f| f =~ %r{app/assets} }
        log 'rake tmp:cache:clear...'
        `nohup rake tmp:cache:clear RAILS_ENV=production > /dev/null &`
        log 'rake ts...'
        `nohup rake ts:stop ts:index ts:start RAILS_ENV=production > /dev/null &`
        log 'sidekiq...'
        `nohup service sidekiq restart > /dev/null &`
        log 'Deploy local: OK!'
      end

      protected

      def git
        Wrapper::Git
      end

      def ask_for_server
        range_end = servers.size + 1
        log <<-LIST
Servers:
  #{servers.keys.tap { |a| a.push '<Add new>' }.map.with_index { |name, index| "#{index + 1}. #{name}" }.join("\n  ")}
        LIST
        index = ask_for_valid('Choose server', "(1 - #{range_end})", 1..range_end).to_i - 1
        ask_for_create_server if index == servers.size

        servers[servers.keys[index]] || ask_for_server
      end

      def ask_for_create_server
        name = ask_for_valid 'Server name:', nil, /\A[a-z0-9\.]+\z/i
        config = {
          'host' => ask_for_valid('Host:', nil, /\A[a-z0-9\.]+\z/i),
          'port' => ask_for_valid('Port', "(0-65535):", 0..65_535),
          'user' => ask_for_valid('User:', '', /\A[a-z0-9_]+\z/i),
          'password' => ask_for_valid('password:', '(min size 4)', /\A.{4,}\z/i),
          'working_dir' => ask_for_valid('Working dir:', '', %r{\A[a-z0-9_/\\\-\.]+\z}i)
        }

        add_server name, config
      end

      def servers
        @servers ||= JSON.load(File.read(SERVERS_FILE, mode: 'a+')) || {}
      end

      def add_server(name, config)
        servers[name] = config
        File.write(SERVERS_FILE, JSON.dump(servers))
      end
    end
  end
end
