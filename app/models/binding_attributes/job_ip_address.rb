class BindingAttributes::JobIpAddress < BindingAttribute
  # specific to this BindingAttribute
  attr_accessor :job_name, :job_index

  def value
    self.job_index ||= 0
    vm = deployment_vms.find do |vm|
      vm['job_name'] == job_name &&
      vm['index'] == job_index
    end
    if vm
      vm['ips'].first
    end
  end

  def deployment_vms
    vms, task_id = bosh_director_client.fetch_vm_state(deployment_name)
    vms
  end
end