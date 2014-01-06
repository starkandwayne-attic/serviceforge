require 'spec_helper'

describe Generators::GenerateDeploymentSpiffFile do
  let(:service_id)      { '1683fe81-b492-4e92-8282-0cdca7c316e1' } # redis-dedicated-bosh-lite
  let(:service)         { Service.find_by_id(service_id) }
  let(:deployment_name) { 'deployment-name' }
  let(:director_uuid)   { 'director-uuid' }

  it "creates DeploymentStub for redis" do
    generator = Generators::GenerateDeploymentSpiffFile.new(
      service: service, deployment_name: deployment_name)
    expect(generator).to receive(:bosh_director_uuid).and_return(director_uuid)

    stub = generator.generate
    expect(stub).to eq(<<-YAML)
---
meta:
  environment: #{deployment_name}
  security_groups:
    - default
director_uuid: #{director_uuid}
releases:
  - name: redis
    version: 2
properties:
  redis: {}
    YAML
  end
end
