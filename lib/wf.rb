require 'json'
require 'pry'
require 'sshkit'
require 'sshkit/dsl'
require 'github_api'
require 'cocaine'

require_relative 'wf/version'

require_relative 'wf/wrapper/logger'
require_relative 'wf/wrapper/cmd/table_multi_handler'
require_relative 'wf/wrapper/cmd/table_one_handler'
require_relative 'wf/wrapper/cmd/draw'
require_relative 'wf/wrapper/cmd'
require_relative 'wf/wrapper/github'
require_relative 'wf/wrapper/git/basic'
require_relative 'wf/wrapper/git'
require_relative 'wf/wrapper/rubocop'

require_relative 'wf/deploy'
require_relative 'wf/install'
require_relative 'wf/structure'
require_relative 'wf/task'

# Work manager
module Wf
  # Your code goes here...
end
