class ServiceBinding
  include ActiveModel::Model

  attr_accessor :id, :service_instance, :credentials

  def self.find(service_instance, id)
      if node = $etcd.get("/service_instances/#{service_instance.id}/service_bindings/#{id}/model")
        attributes = JSON.parse(node.value)
        attributes["service_instance"] = service_instance
        attributes.delete("service_instance_id")
        new(attributes)
      end
    rescue Net::HTTPServerException
      # key not in etcd
  end

  def save
    self.credentials = {
      "host" => "10.244.0.6",
      "hostname" => "10.244.0.6",
      "port" => 4001
    }
    $etcd.set("/service_instances/#{service_instance.id}/service_bindings/#{id}/model", to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{service_instance.id}/service_bindings/#{id}/model")
  end

  def attributes
    {
      "id" => id,
      "service_instance_id" => service_instance.id,
      "credentials" => credentials
    }
  end

  def to_json(*)
    attributes.to_json
  end
end
