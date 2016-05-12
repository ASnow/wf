module Wf
  module Wrapper
    class Git
      # git basic commands to switch branch
      module Branch
        def remove_branch branch
          run 'push origin --delete :branch', with: { branch: branch }
        end

        def current_branch
          run('rev-parse --abbrev-ref HEAD').split("\n")[0]
        end

        def branch?(name)
          !run('branch --list :name', with: { name: name }).empty?
        end

        def in_branch(branch)
          return_to = current_branch
          return yield if return_to == branch

          with_stash do
            switch_to branch
            yield
            switch_to return_to
          end
        end

        def remote_branches
          exec_output_list(run('ls-remote --heads origin')).map{|branch| branch.gsub(%r{\A.*?refs/heads/}, '') }
        end

        def branch_subtree_for(prefix)
          result = run 'branch -a --list :mask', with: { mask: "#{prefix}/*" }
          branch_subtree = exec_output_list result

          branch_subtree.sort_by { |a| a.split('/').last.split('.').map(&:to_i) }
        end

        def local_branches
          exec_output_list(run('branch'))
        end
      end
    end
  end
end
