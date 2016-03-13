module Wf
  module Wrapper
    # github API wrapper
    module Github
      module_function

      NAMESPACE = 'asnow'.freeze
      PROJECT = 'wf'.freeze

      def github
        raise 'Установите переменную среды GITHUB_BASIC_AUTH' unless ENV['GITHUB_BASIC_AUTH']
        @github = ::Github.new basic_auth: ENV['GITHUB_BASIC_AUTH']
      end

      def create_pull_request(comment, to_branch)
        Cmd.run 'hub', 'pull-request -m :comment -b :to_branch', with: { comment: comment, to_branch: to_branch }
      end

      def github_open_pull_requests
        github_pull_requests.list(state: 'open', auto_pagination: true)
      end

      def github_pull_request(number)
        github.pull_requests.get(NAMESPACE, PROJECT, number.to_i)
      end

      def github_pull_requests
        github.pull_requests(user: NAMESPACE, repo: PROJECT)
      end

      def github_pull_request_merge(number)
        github.pull_requests.merge(NAMESPACE, PROJECT, number.to_i)
      end

      def hub_check?
        Cmd.run 'hub', '--version', return: :bool
      end
    end
  end
end
