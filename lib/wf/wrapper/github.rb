module Wf
  module Wrapper
    # github API wrapper
    module Github
      module_function

      NAMESPACE = 'asnow'.freeze
      PROJECT = 'wf'.freeze

      def github
        raise 'Установите переменную среды GITHUB_BASIC_AUTH' unless ENV['GITHUB_BASIC_AUTH']
        @github = ::Github.new basic_auth: ENV['GITHUB_BASIC_AUTH'], user: NAMESPACE, repo: PROJECT
      end

      def create_pull_request(comment, to_branch)
        unless pull_request_open? Git.current_branch, to_branch
          github_pull_requests.create(
            title: comment,
            body: "",
            head: Git.current_branch,
            base: to_branch
          )
        end
      end

      def pull_request_open?(head, base)
        github_open_pull_requests.detect do |pr|
          pr.head.ref == head.to_s && pr.base.ref == base.to_s
        end
      end

      def github_open_pull_requests
        github_pull_requests.list(state: 'open', auto_pagination: true)
      end

      def github_pull_request(number)
        github.pull_requests.get(number: number.to_i)
      end

      def github_pull_requests
        github.pull_requests
      end

      def github_pull_request_merge(number)
        github.pull_requests.merge(number: number.to_i)
      end
    end
  end
end
