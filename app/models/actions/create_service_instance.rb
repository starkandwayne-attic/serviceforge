class Actions::CreateServiceInstance
  include ActiveModel::Model

  attr_accessor :service_id, :service_instance_id, :deployment_uuid_name

  def save
    $etcd.set("/actions/create_service_instances/#{service_instance_id}", to_json)
  end

  def perform
    deployment_stub
  end

  def destroy
    $etcd.delete("/actions/create_service_instances/#{service_instance_id}")
  end

  def to_json(*)
    {
      "service_id" => service_id,
      "service_instance_id" => service_instance_id
    }.to_json
  end

  private
  def deployment_stub
    generate_deployment_uuid_name
    Generators::GenerateDeploymentStub.new(bosh_director_uuid: director_uuid, deployment_name: deployment_uuid_name).generate_stub
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
    self.deployment_uuid_name ||= UUIDTools::UUID.timestamp_create.to_s
  end
end