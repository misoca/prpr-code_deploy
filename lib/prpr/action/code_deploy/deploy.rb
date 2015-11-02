require 'aws-sdk-resources'

module Prpr
  module Action
    module CodeDeploy
      class Deploy < Base
        def call
          if name = deployment_group_name(event)
            deployment = create_deployment(name, deploy_commit)
            Prpr::Publisher::Adapter::Base.broadcast message(deployment)
          end
        end

        private

        def deploy_commit
          event.after
        end

        def deployment_group_name(event)
          if event.ref =~ %r(deployment/(.*))
            env.format(:code_deploy_group, { branch: $1 })
          else
            nil
          end
        end

        def aws
          @aws ||= ::Aws::CodeDeploy::Client.new(
            region: env[:code_deploy_region] || 'ap-northeast-1',
            access_key_id: env[:code_deploy_aws_key],
            secret_access_key: env[:code_deploy_aws_secret],
          )
        end

        def create_deployment(deployment_group_name, commit_id)
          aws.create_deployment({
            application_name: env[:code_deploy_application_name],
            deployment_group_name: deployment_group_name,
            revision: {
              revision_type: "GitHub",
              git_hub_location: {
                repository: env[:code_deploy_repository],
                commit_id: commit_id
              }
            }
          })
        end

        def message(deployment)
          Prpr::Publisher::Message.new(
            body: deployment.deployment_id,
            from: { login: 'aws' },
            room: env[:code_deploy_room])
        end
      end
    end
  end
end
