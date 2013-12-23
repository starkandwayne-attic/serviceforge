class Generators::GenerateDeploymentStub
  include ActiveModel::Model

  attr_accessor :bosh_director_uuid, :deployment_name

  def generate_stub
    base_stub.
      gsub("NAME", deployment_name).
      gsub("PLACEHOLDER-DIRECTOR-UUID", bosh_director_uuid)
  end

  def base_stub
    <<-YAML
---
meta:
  environment: NAME
  security_groups:
    - default
director_uuid: PLACEHOLDER-DIRECTOR-UUID
releases:
  - name: etcd
    version: 2
properties:
  etcd: {}
    YAML
  end
end