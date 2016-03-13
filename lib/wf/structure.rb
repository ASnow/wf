module Wf
  # Define work process structure
  class Structure
    class << self
      LOCAL_PREFIX = 'feature/'.freeze
      REMOTE_PREFIX = 'feature/'.freeze
      include Wrapper::Cmd

      def git
        Wrapper::Git
      end

      def extract_target_param!(param)
        target_branch = target_branch_by_param(param) || ask_target_branch
        log "Base on: #{target_branch}"
        target_branch
      end

      def target_branch_by_param(param)
        case param
        when /\Ah(otfix)?\z/i
          last_hotfix
        when /\Ar(elease)?\z/i
          last_release
        else
          :master
        end
      end

      def ask_target_branch
        answer = ask_for_valid 'Select base branch', '(m/h/r)', /m(aster)?|h(otfix)?|r(elease)?/i
        target_branch_by_param answer
      end

      def remote_feature_branch(feature)
        "#{REMOTE_PREFIX}#{feature}"
      end

      def local_feature_branch(feature)
        "#{LOCAL_PREFIX}#{feature}"
      end

      def last_hotfix
        git.branch_subtree_for('hotfix').last
      end

      def last_release
        git.branch_subtree_for('release').last
      end

      def pr_updates
        Wrapper::Github.github_open_pull_requests.each do |pr|
          git.in_branch pr.head.ref do
            git.with_merged pr.base.ref do
              git.push pr.head.ref
            end
          end
        end
      end

      def pr_merge(number)
        pr = Wrapper::Github.github_pull_request number
        if pr
          if pr.merged
            log "PR #{number} already merged"
          else
            Wrapper::Github.github_pull_request_merge number
            tree_update
            log "PR #{number} merged"
          end
        else
          log "PR #{number} not found"
        end
      end

      def pr_list
        Wrapper::Github.github_open_pull_requests.each do |pr|
          log "#{pr.number} :: #{pr.base.ref} < #{pr.head.ref}  : #{pr.title}"
        end
      end

      def tree_update
        update_queue = git.branch_subtree_for('hotfix') + git.branch_subtree_for('release') + [:master]
        update_queue.each_cons(2) do |up, down|
          git.in_branch down do
            git.with_merged up do
              git.push down
            end
          end
        end
        pr_updates if boolean_ask 'Update Pull requests?'
      end

      def release_hotfix(version, comment)
        hotfix = "hotfix/#{version}"

        restore_stash = true if git.uncommited?
        git.in_branch hotfix do
          if restore_stash
            git.run 'stash apply', return: :bool
            git.commit! git.get_comment(comment) if git.ask_to_commit
          end
          git.push hotfix
          log 'Create tag'
          git.run "tag -a v#{version} -m 'hotfix version #{version}'", return: :bool
          git.in_branch 'master' do
            git.with_merged hotfix do
              git.push :master
            end
          end
          git.in_branch 'stable' do
            git.with_merged hotfix do
              git.push :stable
            end
          end
          # `git push origin --delete #{hotfix}`
        end
      end

      def release_open(version)
        release = "release/#{version}"
        git.in_branch 'master' do
          git.in_branch release do
            git.with_merged 'master' do
              git.push release
            end
          end
        end
      end

      def release_close(version)
        release = "release/#{version}"
        git.in_branch 'master' do
          git.in_branch release do
            git.push release
            log 'Create tag'
            git.run "tag -a v#{version} -m 'release version #{version}'", return: :bool
            git.in_branch 'master' do
              log 'Merge master'
              git.with_merged release do
                git.push :master
              end
            end
            git.in_branch 'stable' do
              log 'Merge stable'
              git.with_merged release do
                git.push :stable
              end
            end
            git.push "--delete #{release}"
          end
        end
      end
    end
  end
end
