module Wf
  module Wrapper
    # Hadles interaction with command line: command execution, user inputs
    module Cmd
      module Draw
        def draw_columns(list)
          return if !list || list.empty?
          term_rows, term_cols = STDIN.winsize

          max_size = list.max_by(&:size).size + 4
          if max_size > term_cols / 2
            table_cols = 1
            col_size = term_cols
          else
            table_cols = term_cols / max_size
            col_size = term_cols / table_cols
          end

          list.each_slice(table_cols) do |group|
            puts group.map { |item| item.ljust(col_size) }.join('')
          end
          [col_size, table_cols]
        end

        def draw_checkboxes(list, selects = [])
          draw_list = list.zip(selects).map { |(item, select)| " [#{select ? 'x' : ' '}] #{item}" }
          col_size, table_cols = draw_columns draw_list
          helper = TableMultiHandler.new(list, selects, col_size, table_cols)
          IO.console << "\x1b[#{helper.lines}A\x1b[2C"
          result = interact do |key|
            case key
            when "\e[B" then helper.down
            when "\e[C" then helper.next
            when "\e[D" then helper.prev
            when "\e[A" then helper.up
            when "\r", "\n" then break true
            when ' ' then helper.toggle
            end

            false
          end
          IO.console << "\x1b[#{helper.lines}B"

          result ? helper.result : []
        end

        def draw_select(list, selects = [])
          draw_list = list.zip(selects).map { |(item, select)| " [#{select ? 'x' : ' '}] #{item}" }
          col_size, table_cols = draw_columns draw_list
          helper = TableOneHandler.new(list, selects, col_size, table_cols)
          IO.console << "\x1b[#{helper.lines}A\x1b[2C"
          result = interact do |key|
            case key
            when "\e[B" then helper.down
            when "\e[C" then helper.next
            when "\e[D" then helper.prev
            when "\e[A" then helper.up
            when "\r", "\n" then break true
            when ' ' then helper.toggle
            end

            false
          end
          IO.console << "\x1b[#{helper.lines}B"

          result ? helper.result : []
        end
      end
    end
  end
end
