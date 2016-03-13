module Wf
  module Wrapper
    module Cmd
      include Logger
      module_function
      
      def run *args
        options = {}
        if args.last.is_a? Hash
          options = args.pop
        end
        variables = options.delete(:with) || {}
        return_type = options.delete(:return)

        line = if args.first.is_a? Cocaine::CommandLine
          args.first
        else
          Cocaine::CommandLine.new(*args, options)
        end
        case return_type
        when :both then [line.run(variables), line]
        when :cmd then line
        when :bool
          begin
            line.run(variables)
            true
          rescue Cocaine::CommandLineError => e
            puts e
            false
          end
        else
          line.run(variables)
        end
      end

      def boolean_ask(msg)
        answer = ask_for_valid msg, "(y/n)", /y(es)?|да|n(o)?|нет/i
        answer =~ /y(es)?|да/i
      end

      def ask_for_valid(msg, offer, validator)
        loop do
          log "#{msg} #{offer}"
          answer = $stdin.gets
          return answer if answer =~ validator
        end
      end
    end
  end
end
