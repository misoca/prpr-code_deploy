require 'aws-sdk-resources'

module Prpr
  module Action
    module CodeDeploy
      class Deploy < Base
       def call
         if deploy_branch?
           deployment = create_deployment(deploy_commit)
           Prpr::Publisher::Message.new(body: deployment.deployment_id, from: 'aws', room: env[:code_deploy_room])
         end
       end

       private

       def deploy_commit
         event.after
       end

       def deploy_branch?
         event.ref =~ %r(deployment/dev)
       end

       def aws
         @aws ||= ::Aws::CodeDeploy::Client.new(
           region: env[:code_deploy_region] || 'ap-northeast-1',
           access_key_id: env[:code_deploy_aws_key],
           secret_access_key: env[:code_deploy_aws_secret],
         )
       end

       def create_deployment(commit_id)
         aws.create_deployment({
           application_name: env[:code_deploy_application_name],
           deployment_group_name: env[:code_deploy_group_name],
           revision: {
             revision_type: "GitHub",
             git_hub_location: {
               repository: env[:code_deploy_repository],
               commit_id: commit_id
             }
           }
         })
       end
      end
    end
  end
end
