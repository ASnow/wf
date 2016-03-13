module Wf
  # define working process structures
  class Structure
    class << self
      LOCAL_PREFIX = 'feature/'.freeze
      REMOTE_PREFIX = 'feature/'.freeze
      include Wrapper::Cmd

      def extract_target_param!(param)
        target_branch = target_branch_by_param(param) || ask_target_branch
        log "Base on: #{target_branch}"
        target_branch
      end

      def target_branch_by_param(val)
        case val
        when 'hotfix', 'h'
          last_hotfix
        when 'master', 'm'
          :master
        end
      end

      def ask_target_branch
        answer = ask_for_valid 'Select base branch', '(m/h/r)', /m(aster)?|h(otfix)?|r(elease)?/i
        case answer
        when /h(otfix)?/i
          last_hotfix
        when /r(elease)?/i
          last_release
        else
          :master
        end
      end

      def remote_feature_branch(feature)
        "#{REMOTE_PREFIX}#{feature}"
      end

      def local_feature_branch(feature)
        "#{LOCAL_PREFIX}#{feature}"
      end

      def last_hotfix
        branch_subtree_for('hotfix').last
      end

      def last_release
        branch_subtree_for('release').last
      end

      def pr_updates
        github_open_pull_requests.each do |pr|
          in_branch pr.head.ref do
            with_merged pr.base.ref do
              `git push origin #{pr.head.ref}`
            end
          end
        end
      end

      def pr_merge(args)
        number = args[0]
        pr = github_pull_request number
        if pr
          if pr.merged
            log "PR #{number} already merged"
          else
            github_pull_request_merge number
            tree_update
            log "PR #{number} merged"
          end
        else
          log "PR #{number} not found"
        end
      end

      def pr_list
        github_open_pull_requests.each do |pr|
          log "#{pr.number} :: #{pr.base.ref} < #{pr.head.ref}  : #{pr.title}"
        end
      end

      def tree_update
        update_queue = branch_subtree_for('hotfix') + branch_subtree_for('release') + [:master]
        update_queue.each_cons(2) do |up, down|
          in_branch down do
            with_merged up do
              `git push origin #{down}`
            end
          end
        end
        pr_updates if boolean_ask 'Update Pull requests?'
      end

      def release_hotfix(args)
        version = args.first
        args = args[1..-1]
        hotfix = "hotfix/#{version}"

        restore_stash = true if uncommited?
        in_branch hotfix do
          if restore_stash
            `git stash apply`
            commit! get_comment(args[1]) if Git.ask_to_commit
          end
          `git push origin "#{hotfix}"`
          log 'Create tag'
          `git tag -a v#{version} -m 'hotfix version #{version}'`
          in_branch 'master' do
            with_merged hotfix do
              `git push origin master`
            end
          end
          in_branch 'stable' do
            with_merged hotfix do
              `git push origin stable`
            end
          end
          # `git push origin --delete #{hotfix}`
        end
      end

      def release_open(args)
        cmd, version = *args
        version = cmd if cmd != 'open'

        release = "release/#{version}"
        in_branch 'master' do
          in_branch release do
            with_merged 'master' do
              `git push origin "#{release}"`
            end
          end
        end
      end

      def release_close(args)
        version = args.first
        release = "release/#{version}"
        in_branch 'master' do
          in_branch release do
            `git push origin "#{release}"`
            log 'Create tag'
            `git tag -a v#{version} -m 'release version #{version}'`
            in_branch 'master' do
              log 'Merge master'
              with_merged release do
                `git push origin master`
              end
            end
            in_branch 'stable' do
              log 'Merge stable'
              with_merged release do
                `git push origin stable`
              end
            end
            `git push origin --delete #{release}`
          end
        end
      end
    end
  end
end
