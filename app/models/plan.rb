class Plan
  attr_reader :id, :name, :description, :metadata, :bosh_deployment_stub

  def self.build(attrs)
    new(attrs)
  end

  def initialize(attrs)
    @id          = attrs.fetch('id')
    @name        = attrs.fetch('name')
    @description = attrs.fetch('description')
    @metadata    = attrs.fetch('metadata', nil)
    @bosh_deployment_stub = attrs.fetch('bosh_deployment_stub', {})
  end

  def to_hash
    {
      'id'          => self.id,
      'name'        => self.name,
      'description' => self.description,
      'metadata'    => self.metadata,
    }
  end

  # spiff YAML stub that applies service plan specific configuration
  # For example, number of servers/jobs in the cluster
  def bosh_deployment_stub_yaml
    bosh_deployment_stub.try(:to_yaml)
  end
end