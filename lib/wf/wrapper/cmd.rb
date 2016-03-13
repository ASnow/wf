module Wf
  module Wrapper
    # Hadles interaction with command line: command execution, user inputs
    module Cmd
      include Logger

      module_function

      def run_with_bool_strategy(line, variables)
        line.run(variables) && true
      rescue Cocaine::CommandLineError => e
        puts e
        false
      end

      def run_with_strategy(strategy, line, variables)
        case strategy
        when :both then [line.run(variables), line]
        when :cmd then line
        when :bool
          run_with_bool_strategy(line, variables)
        else
          line.run(variables)
        end
      end

      def run(*args)
        options = {}
        options = args.pop if args.last.is_a? Hash
        variables = options.delete(:with) || {}
        return_type = options.delete(:return)

        line = if args.first.is_a? Cocaine::CommandLine
                 args.first
               else
                 Cocaine::CommandLine.new(*args, options)
               end

        run_with_strategy return_type, line, variables
      end

      def boolean_ask(msg)
        answer = ask_for_valid msg, '(y/n)', /y(es)?|да|n(o)?|нет/i
        answer =~ /y(es)?|да/i
      end

      def ask_for_valid(msg, offer, validator)
        loop do
          log "#{msg} #{offer}"
          answer = $stdin.gets
          begin
            return answer if answer =~ validator
          rescue
            nil
          end
        end
      end
    end
  end
end
