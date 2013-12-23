require 'spec_helper'
require 'generators/generate_deployment_stub' # forced loading to avoid 'not a defined constant' rspec-fire issue

describe Actions::CreateServiceInstance do
  let(:generator) { instance_double("Generators::GenerateDeploymentStub") }
  let(:service_id) { 'service-id-1' }
  let(:service)   { instance_double("Service") }
  let(:service_instance_id) { 'service-instance-id-1' }
  let(:deployment_stub) { "---\nname: something" }
  let(:director_uuid) { "director-uuid" }
  let(:deployment_name) { "deployment-name" }

  before do
    begin
      $etcd.delete("/actions", recursive: true)
    rescue Net::HTTPServerException
    end
  end


  it "has lifecycle" do
    uuid_klass = class_double("UUIDTools::UUID").as_stubbed_const
    uuid_klass.should_receive(:timestamp_create).and_return(deployment_name)

    action = Actions::CreateServiceInstance.new(service_id: service_id, service_instance_id: service_instance_id)
    action.save

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/create_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name
    })

    ##
    ## Generate deployment manifest
    ##
    service_klass = class_double("Service").as_stubbed_const
    service_klass.should_receive(:find_by_id).and_return(service)
    service.should_receive(:bosh).and_return({"director_uuid" => director_uuid})

    gds_klass = class_double("Generators::GenerateDeploymentStub").as_stubbed_const
    gds_klass.should_receive(:new).with({bosh_director_uuid: director_uuid, deployment_name: deployment_name}).and_return(generator)

    generator.should_receive(:generate_stub).and_return(deployment_stub)
    action.perform

    action.destroy
    expect{ $etcd.get("/actions/create_service_instances/#{service_instance_id}") }.to raise_error(Net::HTTPServerException)
  end
end
