class Actions::WaitForServiceInstanceDeployment
  include EtcdModel

  attr_accessor :service_id
  attr_accessor :service_instance_id

  def perform
    return unless service_instance.try(:deploying?)
    unless service_instance.latest_bosh_deployment_task_id
      raise ServiceInstance::BadInternalState, "ServiceInstance is deploying; but no latest_bosh_task_id available"
    end
    # Note: the latest_bosh_task_id should be a "create deployment" in BOSH
    state = bosh_director_client.track_task(service_instance.latest_bosh_deployment_task_id)
    case state.to_sym
      when :done
        service_instance.deployment_successful!
      when :running
        service_instance.deploying!
      else
        service_instance.failed_deployment!
    end
  end
end