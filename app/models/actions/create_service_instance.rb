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
class Actions::CreateServiceInstance
  include EtcdModel

  # required for constructor
  attr_accessor :service_id, :service_plan_id, :service_instance_id

  # set during usage
  attr_accessor :deployment_name, :bosh_task_id

  def save
    generate_deployment_uuid_name
    $etcd.set("/actions/create_service_instances/#{service_instance_id}", to_json)
  end

  # assumes #generate_deployment_uuid_name has already been called
  def perform
    allocate_infrastructure_to_service_instance
    deployment_spiff_file = generate_deployment_spiff_file
    infrastructure_spiff_file = generate_infrastructure_spiff_file
    deployment_manifest = generate_deployment_manifest(deployment_spiff_file, infrastructure_spiff_file)
    perform_bosh_deploy_and_save_task_id(deployment_manifest)
    track_task
  end

  def to_json(*)
    {
      'service_id' => service_id,
      'service_plan_id' => service_plan_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => bosh_task_id
    }.to_json
  end

  private
  def service_stub_paths
    service.bosh_service_stub_paths
  end

  def generate_deployment_spiff_file
    Generators::GenerateDeploymentSpiffFile.new(
      service: service, deployment_name: deployment_name).generate
  end

  def generate_infrastructure_spiff_file
    infrastructure_network.deployment_stub
  end

  def generate_deployment_manifest(deployment_stub, infrastructure_stub)
    # TODO how pass through binding information? (not required for etcd or redis)
    Generators::GenerateDeploymentManifest.new({
      service_stub_paths: service_stub_paths,
      infrastructure_stub: infrastructure_stub,
      deployment_stub: deployment_stub,
      service_plan_stub: service_plan_stub
    }).generate_manifest
  end

  def perform_bosh_deploy_and_save_task_id(deployment_manifest)
    status, self.bosh_task_id = bosh_director_client.deploy(deployment_manifest)
    save
  end

  def track_task
    bosh_director_client.track_task(bosh_task_id)
    # TODO did it succeed for fail?
  end

  def allocate_infrastructure_to_service_instance
    unless service_instance.infrastructure_network
      allocated_infrastructure = bosh_director_client.allocate_infrastructure_network
      service_instance.infrastructure_network = allocated_infrastructure
      service_instance.save
    end
  end

  def infrastructure_network
    service_instance.infrastructure_network
  end

  def service_plan_stub
    service_plan.bosh_deployment_stub_yaml
  end

  def deployment_name_prefix
    service.deployment_name_prefix
  end

  def generate_deployment_uuid_name
    self.deployment_name ||= "#{deployment_name_prefix}-#{service_instance_id}"
  end
end