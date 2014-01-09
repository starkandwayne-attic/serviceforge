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
    perform_bosh_deploy_and_update_service_instance(deployment_manifest)
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
    infrastructure_network.try(:deployment_stub)
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

  def perform_bosh_deploy_and_update_service_instance(deployment_manifest)
    status, self.bosh_task_id = bosh_director_client.deploy(deployment_manifest)
    save
    if status == :running
      service_instance.latest_bosh_deployment_task_id = bosh_task_id
      service_instance.deploying!
    else
      service_instance.failed_deployment!
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
end