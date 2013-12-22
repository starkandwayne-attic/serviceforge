require 'spec_helper'

describe Generators::GenerateDeploymentStub do
  let(:deployment_uuid_name) { "SOME-UUID-VALUE" }
  let(:director_uuid) { "director-uuid" }

  subject { GenerateDeploymentStub.new(service_instance) }

  it "creates DeploymentStub" do
    # uuidtools = class_double("UUIDTools::UUID")
    # uuidtools.should_receive(:timestamp_create).and_return(deployment_uuid_name)

    stub = Generators::GenerateDeploymentStub.new(bosh_director_uuid: director_uuid, deployment_name: deployment_uuid_name).generate_stub
    expect(stub).to eq(<<-YAML)
---
meta:
  environment: #{deployment_uuid_name}
  security_groups:
    - default
director_uuid: #{director_uuid}
releases:
  - name: etcd
    version: latest
properties:
  etcd: {}
    YAML
  end
end
