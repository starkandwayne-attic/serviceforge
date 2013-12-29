# Example usage:
#     deployment_name = "etcd-c7525ae2-bb73-4f4c-a654-66ae6f5afc86"
#     command = BindingCommands::Bosh::DeploymentVmState.new({
#       service_id: "b9698740-4810-4dc5-8da6-54581f5108c4",
#       deployment_name: deployment_name
#     })
#     command.perform
#     command.to_json
class BindingCommands::Bosh::DeploymentVmState
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service_id, :deployment_name

  attr_reader :vms_state, :bosh_task_id

  def perform
    @vms_state, @bosh_task_id = bosh_director_client.fetch_vm_state(deployment_name)
    # Delete internal BOSH IDs from public visibility
    @vms_state.each do |vm|
      vm.delete('vm_cid')
      vm.delete('agent_id')
    end
  end

  def to_json(*)
    vms_state.to_json
  end
end