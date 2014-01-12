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

    before_transition any => any, do: :debug_pre_state_change
    after_transition any => any, do: :debug_post_state_change

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
    $etcd.set("/service_instances/#{service_instance_id}/model", to_json)
  end

  def destroy
    $etcd.delete("/service_instances/#{service_instance_id}", recursive: true)
  end

  def to_cf_json
    {
      'dashboard_url' => dashboard_url
    }.to_json
  end

  def to_json(*)
    attributes.to_json
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

  def dashboard_url
    @dashboard_url ||= begin
      uri = URI.parse(request_base_url)
      uri.path = "/service_instances/#{service_instance_id}"
      uri.user = Settings.auth_username
      uri.password = Settings.auth_password
      uri.to_s
    end
  end

  private
  def debug_pre_state_change
    puts "[pre:#{state}:#{service_instance_id}]"
  end

  def debug_post_state_change
    puts "[post:#{state}:#{service_instance_id}]"
  end

  def request_base_url
    Settings.base_url
  end
end
