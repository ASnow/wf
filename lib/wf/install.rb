require "fileutils"

module Wf
  # installs wf
  class Install
    class << self
      include Wrapper::Cmd


      def install
        log 'Install bundler'
        FileUtils.mkdir_p '.bundle'
        File.open('.bundle/Gemfile.local', "w+") do |fp|
          fp.write <<-GEMFILE
# Include the regular Gemfile
class Bundler::Dsl
  def gemspec_with_feature(opts = nil)
    opts ||= {}
    opts[:path] ||= "../."

    gemspec_without_feature opts
  end
  alias_method :gemspec_without_feature, :gemspec
  alias_method :gemspec, :gemspec_with_feature
end
default_dir = File.expand_path('../..', __FILE__)
Dir.chdir(default_dir)
eval File.read('Gemfile')

# Add any gems and groups that you don't want to keep local
group :development do
  gem 'wf', github: 'asnow/wf'
end
GEMFILE
        end
        log "Run: bundle --gemfile '.bundle/Gemfile.local'"
        result = run 'bundle', '--gemfile :file', with: {file: '.bundle/Gemfile.local'}, return: :bool
        log "Result: #{result ? "OK" : "FIAL"}"
      end
    end
  end
end
