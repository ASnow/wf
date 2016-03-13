module Wf
  module Wrapper
    module Logger
      module_function
      
      def log(text)
        puts "[WF]: #{text}"
      end
    end
  end
end
