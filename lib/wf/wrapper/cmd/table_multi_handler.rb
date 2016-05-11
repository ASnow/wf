module Wf
  module Wrapper
    # Hadles interaction with command line: command execution, user inputs
    module Cmd
      class TableMultiHandler
        def initialize(list, selects, col_size, table_cols)
          @list = list
          @col_size = col_size
          @table_cols = table_cols.to_i
          @current = 0
          @last_position = [0, 0]
          @selects = selects
        end

        def next
          goto if change_by 1
        end

        def prev
          goto if change_by(-1)
        end

        def up
          goto if change_by(-@table_cols)
        end

        def down
          goto if change_by @table_cols
        end

        def lines
          (@list.size.to_f / @table_cols).ceil
        end

        def change_by(by)
          return false unless @list.size > @current + by
          return false if 0 > @current + by
          @current += by
          true
        end

        def toggle
          @selects[@current] = !@selects[@current]
          IO.console << "#{@selects[@current] ? 'x' : ' '}\x1b[1D"
        end

        def result
          @list.zip(@selects).select { |(_, select)| select }.map { |(item, _)| item }
        end

        def goto
          next_position = [@current / @table_cols, (@current % @table_cols) * @col_size]
          rows_diff = next_position[0] - @last_position[0]
          if rows_diff > 0
            IO.console << "\x1b[#{rows_diff}B"
          elsif rows_diff < 0
            IO.console << "\x1b[#{-rows_diff}A"
          end

          cols_diff = next_position[1] - @last_position[1]
          if cols_diff > 0
            IO.console << "\x1b[#{cols_diff}C"
          elsif cols_diff < 0
            IO.console << "\x1b[#{-cols_diff}D"
          end
          @last_position = next_position
        end
      end
    end
  end
end
