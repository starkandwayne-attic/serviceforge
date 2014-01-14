# TODO name: CheckServiceInstanceDeployment
# It performs a state transition
class Actions::UpdateServiceInstanceState
  include EtcdModel

  attr_accessor :service_id
  attr_accessor :service_instance_id

  def perform
    return unless service_instance.try(:deploying?)
    unless service_instance.latest_bosh_deployment_task_id
      raise ServiceInstance::BadInternalState, "ServiceInstance is deploying; but no latest_bosh_task_id available"
    end
    # Note: the latest_bosh_task_id should be a "create deployment" in BOSH
    state = bosh_director_client.task_state(service_instance.latest_bosh_deployment_task_id)
    puts "service_instance_id: #{service_instance_id}"
    puts "state: #{state.inspect}"
    case state.to_sym
      when :done
        service_instance.deployment_successful!
      when :running, :queued, :processing
        service_instance.deploying!
      else
        service_instance.failed_deployment!
    end
  end
end