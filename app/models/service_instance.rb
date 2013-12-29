class ServiceInstance
  include EtcdModel

  attr_accessor :service_instance_id
  attr_accessor :service_id
  attr_accessor :service_plan_id
  attr_accessor :deployment_name

  def self.find_by_id(service_instance_id)
    if node = $etcd.get("/service_instances/#{service_instance_id}/model")
      attributes = JSON.parse(node.value)
      new(attributes)
    end
  rescue Net::HTTPServerException
    # key not in etcd
  end

  def self.create(attributes)
    object = new(attributes)
    object.save
    object
  end

  def save
    $etcd.set("/service_instances/#{service_instance_id}/model", attributes.to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{service_instance_id}/model")
  end

  def to_json(*)
    {}.to_json
  end

  def attributes
    {
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_plan_id' => service_plan_id,
      'deployment_name' => deployment_name
    }
  end
end
