# Example usage:
#     command = BindingCommands::Bosh::DeploymentVmState.new({
#       service_id: "b9698740-4810-4dc5-8da6-54581f5108c4",
#       deployment_name: "etcd-X-Y-Z"
#     }
#     command.perform
#     command.to_json
class BindingCommands::Bosh::DeploymentVmState
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service_id, :deployment_name

  attr_reader :vms_state, :bosh_task_id

  def perform
    @vms_state, @bosh_task_id = bosh_director_client.fetch_vm_state(deployment_name)
  end

  def to_json(*)
    vms_state.to_json
  end
end