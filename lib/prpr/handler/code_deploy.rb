module Prpr
    module Handler
      class CodeDeploy < Base
        handle Event::Push do
          Action::CodeDeploy::Deploy.new(event).call
        end
      end
    end
end
