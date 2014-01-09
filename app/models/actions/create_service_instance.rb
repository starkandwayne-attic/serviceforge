# Created when Broker received requests to create a new service. Performs the action
# of creating a new service.
#
# Currently the entire behaviour is executed in current thread/process. In future, move
# this into background thread/worker.
#
# For service instances provisioned via BOSH, then a deployment manifest is generated and
# the Service's BOSH is given the request to deploy the Service's release.
#
# Example usage:
#   action = Actions::CreateServiceInstance.new(
#     service_id: 'b9698740-4810-4dc5-8da6-54581f5108c4', # etcd-dedicated-bosh-lite
#     service_plan_id: '6e8ece8c-4fe6-4d58-9aeb-497d6aeba113', # 1-server
#     service_instance_id: 'foobar')
#   action.save
#   action.perform
class Actions::CreateServiceInstance < Actions::ChangeServiceInstance

  def save
    generate_deployment_uuid_name
    $etcd.set("/actions/create_service_instances/#{service_instance_id}", to_json)
  end

  # assumes #generate_deployment_uuid_name has already been called
  def perform
    allocate_infrastructure_to_service_instance
    super
  end

  private
  # If the target BOSH is using a pool of InfrastructureNetworks to
  # manually isolate each deployment's networking from the others,
  # then ask it for an InfrastructureNetwork.
  # Else do nothing.
  def allocate_infrastructure_to_service_instance
    unless service_instance.infrastructure_network
      if allocated_infrastructure = bosh_director_client.allocate_infrastructure_network
        service_instance.infrastructure_network = allocated_infrastructure
        service_instance.save
      end
    end
  end

  def generate_deployment_uuid_name
    self.deployment_name ||= "#{deployment_name_prefix}-#{service_instance_id}"
  end

  def deployment_name_prefix
    service.deployment_name_prefix
  end
end