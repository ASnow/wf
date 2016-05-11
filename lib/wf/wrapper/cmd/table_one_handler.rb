module Wf
  module Wrapper
    # Hadles interaction with command line: command execution, user inputs
    module Cmd
      class TableOneHandler < TableMultiHandler
        def toggle
          restore_current = @current
          @selects.each do |index, value|
            next unless value
            next if index == restore_current
            @current = index
            goto
            @selects[index] = false
            IO.console << " \x1b[1D"
          end
          @current = restore_current
          goto
          @selects[@current] = !@selects[@current]
          IO.console << "#{@selects[@current] ? 'x' : ' '}\x1b[1D"
        end
      end
    end
  end
end
