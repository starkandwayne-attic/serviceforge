# Created when Broker received requests to bind a service. Performs the action
# of fetching live binding information, such as master host address.
#
# Despite the name, it does not modify ServiceBinding. Rather, it fetches the data
# that can be used to update ServiceBinding:
#
# * master_host_address
#
# Example usage:
#   action = Actions::UpdateServiceBinding.new(
#     service_id: 'b9698740-4810-4dc5-8da6-54581f5108c4', # etcd-dedicated-bosh-lite
#     service_instance_id: 'foobar',
#     service_binding_id: 'foobar-myapp',
#     deployment_name: 'etcd-dcb1c536-6c0b-11e3-9bba-8438354ccefa',
#     master_host_job_name: 'etcd_leader_z1')
#   action.save
#   action.perform
class Actions::UpdateServiceBinding
  include ActiveModel::Model

  # required for constructor
  attr_accessor :service_id, :service_instance_id, :service_binding_id
  attr_accessor :deployment_name, :master_host_job_name

  # set during usage
  attr_accessor :master_host_address, :bosh_task_id, :error

  def save
    $etcd.set("/actions/update_service_binding/#{service_binding_id}", to_json)
  end

  def perform
    fetch_vms_state
    determine_master_host_address
    save
  end

  def to_json(*)
    {
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_binding_id' => service_binding_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => bosh_task_id,
      'error' => error,
      'master_host_job_name' => master_host_job_name,
      'master_host_job_index' => master_host_job_index,
      'master_host_address' => master_host_address,
    }.to_json
  end

  private
  def service
    @service ||= Service.find_by_id(service_id)
  end

  def bosh_director_client
    service.bosh
  end

  def fetch_vms_state
    @vms_state, self.bosh_task_id = bosh_director_client.fetch_vm_state(deployment_name)
  end

  def determine_master_host_address
    if master_host_job_state
      self.master_host_address = master_host_job_state["ips"].first
    else
      self.error = "No job found #{master_host_job_name}/#{master_host_job_index}"
    end
  end

  def master_host_job_state
    @master_host_job_state ||= @vms_state.find do |vm_state|
      vm_state["job_name"] == master_host_job_name && vm_state["index"] == master_host_job_index
    end
  end

  def master_host_job_index
    0
  end
end