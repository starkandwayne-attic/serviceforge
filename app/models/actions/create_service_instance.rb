# Created when Broker received requests to create a new service. Performs the action
# of creating a new service.
#
# Currently the entire behaviour is executed in current thread/process. In future, move
# this into background thread/worker.
#
# For service instances provisioned via BOSH, then a deployment manifest is generated and
# the Service's BOSH is given the request to deploy the Service's release.
class Actions::CreateServiceInstance
  include ActiveModel::Model

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
    deployment_stub = generate_deployment_stub
    deployment_manifest = generate_deployment_manifest(deployment_stub)
    perform_bosh_deploy_and_save_task_id(deployment_manifest)
  end

  def destroy
    $etcd.delete("/actions/create_service_instances/#{service_instance_id}")
  end

  def to_json(*)
    {
      "service_id" => service_id,
      "service_instance_id" => service_instance_id,
      "deployment_name" => deployment_name,
      "bosh_task_id" => bosh_task_id
    }.to_json
  end

  private
  def generate_deployment_stub
    Generators::GenerateDeploymentStub.new(bosh_director_uuid: director_uuid, deployment_name: deployment_name).generate_stub
  end

  def generate_deployment_manifest(deployment_stub)
    # TODO how pass through binding information? (not required for etcd or redis)
    Generators::GenerateDeploymentManifest.new(deployment_stub: deployment_stub, service_plan_stub: service_plan_stub).generate_manifest
  end

  def perform_bosh_deploy_and_save_task_id(deployment_manifest)
    self.bosh_task_id = bosh_director_client.deploy(deployment_manifest)
    save
  end

  def service_instance
    @service_instance ||= ServiceInstance.find_by_id(service_instance_id)
  end

  def service_plan_stub
    service_plan.deployment_stub
  end

  def service
    @service ||= Service.find_by_id(service_id)
  end

  def service_plan
    @service_plan || service.find_plan_by_id(service_plan_id)
  end

  def director_uuid
    service.bosh["director_uuid"]
  end

  def bosh_director_client
    service.bosh_director_client
  end

  def generate_deployment_uuid_name
    self.deployment_name ||= UUIDTools::UUID.timestamp_create.to_s
  end
end