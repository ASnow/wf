module Wf
  class Deploy
    class << self
      def deploy
        return puts('Установите переменную среды PROD_NAME') unless ENV['PROD_NAME']
        return puts('Установите переменную среды PROD_PASS') unless ENV['PROD_PASS']
        finished = ('%08x' * 8) % Array.new(8) { rand(0xFFFFFFFF) }
        password = ENV['PROD_PASS']
        Net::SSH.start('10.100.0.111', ENV['PROD_NAME'], password: password, port: 60_022) do |ssh|
          sign_in = false
          remote_call = lambda do |channel, data, &block|
            puts data
            if data =~ /\[sudo\]/
              channel.send_data(password + "\n")
              sign_in = true
            elsif data.include?(finished) || sign_in
              sign_in = false
              block.call
            end
          end
          su = lambda do |user, commands, &block|
            channel_ = ssh.open_channel do |channel|
              channel.request_pty(modes: { Net::SSH::Connection::Term::ECHO => 0 }) do |c, success|
                next unless success
                sign_in = false
                c.exec("sudo su #{user}") do |_sudo_channel, sudo_success|
                  if sudo_success
                    channel.on_data do |_ondata_channel, data|
                      remote_call.call(channel, data) do |_output|
                        cmd = commands.shift
                        if cmd
                          puts "#{user}:$> #{cmd}"
                          cmd = "#{cmd}; echo #{finished}\n"
                          channel.send_data(cmd)
                        else
                          if block
                            block.call channel
                          else
                            channel.do_close
                          end
                        end
                      end
                    end
                    channel.on_close do |_onclose_channel|
                      puts 'Channel closed.'
                    end
                  end
                end
              end
            end
          end

          su.call(:bckp_usr, [
                    '~/backup.sh'
                  ]) do |bckp_usr|
            bckp_usr.do_close
            su.call(:rubyuser, [
                      'cd /opt/obruset',
                      'ruby wf deploy_local',
                      'touch tmp/restart.txt'
                    ]) do |rubyuser|
              rubyuser.do_close
              ssh.close
            end
          end
        end
      end

      def deploy_local
        log 'Deploy local'
        prev_commit = `git rev-parse HEAD`.chomp
        log 'git pull...'
        pull current_branch
        files = `git diff --name-only #{prev_commit}`.split($INPUT_RECORD_SEPARATOR)
        log 'bundle install...'
        `bundle install --without=development test` if files.any? { |f| f =~ /Gemfile(\.lock)?/ }
        log 'rake db:migrate...'
        `rake db:migrate RAILS_ENV=production` if files.any? { |f| f =~ /db\/migrate\/.*\.rb/ }
        log 'localeapp pull...'
        `localeapp pull`
        log 'rake assets:precompile...'
        `rake assets:precompile RAILS_ENV=production` if files.any? { |f| f =~ /app\/assets/ }
        log 'rake tmp:cache:clear...'
        `nohup rake tmp:cache:clear RAILS_ENV=production > /dev/null &`
        log 'rake ts...'
        `nohup rake ts:stop ts:index ts:start RAILS_ENV=production > /dev/null &`
        log 'sidekiq...'
        `nohup service sidekiq restart > /dev/null &`
        log 'Deploy local: OK!'
      end
    end
  end
end
