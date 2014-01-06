# Like CreateServiceInstance, but for an existing BOSH deployment
class Actions::ChangeServiceInstance
  include EtcdModel

  # required for constructor
  attr_accessor :service_id, :service_plan_id, :service_instance_id, :deployment_name

  # set during usage
  attr_accessor :bosh_task_id

  def save
    $etcd.set("/actions/change_service_instances/#{service_instance_id}", to_json)
  end

  def perform
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
    Generators::GenerateInfrastructureSpiffFile.new(
      service: service, infrastructure_network: infrastructure_network).generate
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
    # TODO get final task status and save it
    # TODO handle error if task status isn't :done
  end

  def service_instance
    @service_instance ||= ServiceInstance.find_by_id(service_instance_id)
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
end