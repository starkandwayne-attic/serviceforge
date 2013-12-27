class BindingAttributes::JobIpAddress
  include ActiveModel::Model

  # common
  attr_accessor :service_id, :deployment_name, :deployment_manifest

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

  protected
  def service
    @service ||= Service.find_by_id(service_id)
  end

  def bosh_director_client
    service.bosh
  end

  def deployment_vms
    bosh_director_client.list_vms(deployment_name)
  end
end