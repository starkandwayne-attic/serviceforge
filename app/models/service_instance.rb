class ServiceInstance
  include EtcdModel

  attr_accessor :service_instance_id
  attr_accessor :service_id
  attr_accessor :service_plan_id
  attr_accessor :deployment_name

  attr_accessor :infrastructure_network

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

  def initialize(attrs={})
    infrastructure_network_attrs = attrs.delete('infrastructure_network')
    super(attrs)
    if infrastructure_network_attrs
      self.infrastructure_network = Bosh::InfrastructureNetwork.build(infrastructure_network_attrs)
    end
  end

  def save
    $etcd.set("/service_instances/#{service_instance_id}/model", attributes.to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{service_instance_id}", recursive: true)
  end

  def to_json(*)
    {}.to_json
  end

  def attributes
    {
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_plan_id' => service_plan_id,
      'deployment_name' => deployment_name,
      'infrastructure_network' => infrastructure_network.try(:attributes)
    }
  end
end
