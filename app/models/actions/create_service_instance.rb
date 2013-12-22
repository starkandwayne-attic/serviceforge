class Actions::CreateServiceInstance
  include ActiveModel::Model

  attr_accessor :service_instance_id

  def self.for_service_instance(service_instance)
    new(service_instance_id: service_instance.id)
  end

  def save
    $etcd.set("/actions/create_service_instances/#{service_instance_id}", to_json)
  end

  def destroy
    $etcd.delete("/create_service_instances/#{service_instance_id}")
  end

  def to_json(*)
    {
      "service_instance_id": service_instance_id
    }.to_json
  end
end