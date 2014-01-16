class Actions::WaitForServiceInstanceDeletion
  include EtcdModel

  attr_accessor :service_id
  attr_accessor :service_instance_id

  def perform
    return unless service_instance.try(:destroying?)
    unless service_instance.latest_bosh_deployment_task_id
      raise ServiceInstance::BadInternalState, "ServiceInstance is being destroyed; but no latest_bosh_task_id available"
    end
    # Note: the latest_bosh_task_id should be a "delete deployment" in BOSH
    state = bosh_director_client.track_task(service_instance.latest_bosh_deployment_task_id)
    case state.to_sym
      when :done
        release_networking_and_mark_destroyed
      when :running, :queued
        service_instance.deploying!
      else
        # TODO what to do if "delete deployment" fails after it starts successfully
        service_instance.deletion_failed!
    end

  end

  private
  def release_networking_and_mark_destroyed
    bosh_director_client.release_infrastructure_network(service_instance.infrastructure_network)
    service_instance.deletion_successful!
  end
end