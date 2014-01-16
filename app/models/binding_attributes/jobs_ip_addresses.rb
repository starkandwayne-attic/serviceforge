class BindingAttributes::JobsIpAddresses < BindingAttribute
  # specific to this BindingAttribute
  attr_accessor :job_names

  def value
    vms = deployment_vms.select do |vm|
      job_names.include?(vm['job_name'])
    end
    vms.map { |vm| vm['ips'] }.flatten
  end

  def deployment_vms
    vms, task_id = bosh_director_client.fetch_vm_state(deployment_name)
    vms
  end
end