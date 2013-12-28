class ServiceInstance
  include ActiveModel::Model

  attr_accessor :id
  attr_accessor :service_id
  attr_accessor :plan_id
  attr_accessor :deployment_name

  def self.find_by_id(id)
    if node = $etcd.get("/service_instances/#{id}/model")
      attributes = JSON.parse(node.value)
      new(attributes)
    end
  rescue Net::HTTPServerException
    # key not in etcd
  end

  def save
    $etcd.set("/service_instances/#{id}/model", attributes.to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{id}/model")
  end

  def to_json(*)
    {}.to_json
  end

  def attributes
    {
      'id' => id,
      'service_id' => service_id,
      'plan_id' => plan_id,
      'deployment_name' => deployment_name
    }
  end
end
