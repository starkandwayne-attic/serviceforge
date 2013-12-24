class Plan
  attr_reader :id, :name, :description, :metadata

  def self.build(attrs)
    new(attrs)
  end

  def initialize(attrs)
    @id          = attrs.fetch('id')
    @name        = attrs.fetch('name')
    @description = attrs.fetch('description')
    @metadata    = attrs.fetch('metadata', nil)
  end

  def to_hash
    {
      'id'          => self.id,
      'name'        => self.name,
      'description' => self.description,
      'metadata'    => self.metadata,
    }
  end

  def cluster_size
    @metadata['cluster_size'].to_i
  end

  # spiff YAML stub that applies service plan specific configuration
  # For example, number of servers/jobs in the cluster
  def deployment_stub
    <<-YAML
---
jobs:
  - name: etcd_z1
    instances: #{cluster_size - 1}
    YAML
  end
end