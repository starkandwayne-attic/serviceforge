class ServiceInstance
  include EtcdModel

  attr_accessor :service_instance_id
  attr_accessor :service_id
  attr_accessor :service_plan_id
  attr_accessor :deployment_name

  # Allocated InfrastructureNetwork if required for target BOSH
  attr_accessor :infrastructure_network

  # Internal state
  attr_accessor :state
  attr_accessor :latest_bosh_deployment_task_id

  class BadInternalState < StandardError; end

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

  state_machine :state, :initial => :initialized do
    after_transition any => any, do: :save

    event :deploying do
      transition [:initialized, :running, :deploying] => :deploying
    end
    event :failed_deployment do
      transition [:initialized] => :failed_creation
      transition [:deploying] => :failed_deployment
    end
    event :deployment_successful do
      transition [:deploying] => :running
    end
    event :destroying do
      transition [:running] => :destroying
    end
    event :destroyed do
      transition any => :destroyed
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
      'infrastructure_network' => infrastructure_network.try(:attributes),
      'state' => state,
      'latest_bosh_deployment_task_id' => latest_bosh_deployment_task_id
    }
  end
end
