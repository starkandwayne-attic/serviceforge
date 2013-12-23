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

  attr_accessor :service_id, :service_instance_id, :deployment_name

  def save
    generate_deployment_uuid_name
    $etcd.set("/actions/create_service_instances/#{service_instance_id}", to_json)
  end

  def perform
    deployment_stub = generate_deployment_stub
    deployment_manifest = generate_deployment_manifest(deployment_stub)
  end

  def destroy
    $etcd.delete("/actions/create_service_instances/#{service_instance_id}")
  end

  def to_json(*)
    {
      "service_id" => service_id,
      "service_instance_id" => service_instance_id,
      "deployment_name" => deployment_name
    }.to_json
  end

  private
  def generate_deployment_stub
    Generators::GenerateDeploymentStub.new(bosh_director_uuid: director_uuid, deployment_name: deployment_name).generate_stub
  end

  def generate_deployment_manifest(deployment_stub)
    
  end

  def service_instance
    @service_instance ||= ServiceInstance.find_by_id(service_instance_id)
  end

  def service
    @service ||= Service.find_by_id(service_id)
  end

  def director_uuid
    service.bosh["director_uuid"]
  end

  def generate_deployment_uuid_name
    self.deployment_name ||= UUIDTools::UUID.timestamp_create.to_s
  end
end