class ServiceBinding
  include EtcdModel

  attr_accessor :service_binding_id, :service_instance_id, :credentials

  def self.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id)
    if node = $etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model")
      attributes = JSON.parse(node.value)
      new(attributes)
    end
  rescue Net::HTTPServerException
    # key not in etcd
  end

  def self.create(attributes)
    binding = new(attributes)
    binding.save
    binding
  end

  def save
    $etcd.set("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model", to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}", recursive: true)
  end
end
