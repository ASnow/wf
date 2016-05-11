module Wf
  module Wrapper
    class Git
      # git basic commands to switch branch
      module Switch
        def switch_to(branch, start_point = nil, opts = nil)
          unless branch?(branch)
            start_point = current_branch unless start_point
            in_branch start_point do
              __switch_to branch, "#{opts} -b "
            end
          end
          __switch_to branch, opts
          log "Current branch: #{branch}"
        end

        def __switch_to(branch, opts = nil)
          __switch_loop branch, opts
          pull branch
        end

        def __switch_loop(branch, opts)
          checkout = run("checkout #{opts} :branch", with: { branch: branch }, return: :bool)
          until checkout
            log "Can't switch branch to #{branch} untill changes apply:"
            puts status[1..-1].join("\n")
            log 'Please fix you changes before next:'
            protect_changes do
              checkout = run("checkout #{opts} :branch", with: { branch: branch }, return: :bool)
            end
          end
        end
      end
    end
  end
end
