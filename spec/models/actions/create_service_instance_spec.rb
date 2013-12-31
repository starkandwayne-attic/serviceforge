require 'spec_helper'

describe Actions::CreateServiceInstance do
  let(:stub_generator)        { instance_double("Generators::GenerateDeploymentStub") }
  let(:manifest_generator)    { instance_double("Generators::GenerateDeploymentManifest") }
  let(:service)               { instance_double("Service") }
  let(:service_id)            { 'service-id-1' }
  let(:service_plan)          { instance_double("Plan") }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_stub_paths)    { %w[/path/to/file1.yml /path/to/file2.yml] }
  let(:deployment_stub)       { "---\nname: something" }
  let(:service_plan_stub)     { "---\njobs:\n  - name: etc\n  - instances: 2" }
  let(:director_uuid)         { "director-uuid" }
  let(:deployment_name_prefix) { 'test-etcd' }
  let(:deployment_name)       { "#{deployment_name_prefix}-#{service_instance_id}" }
  let(:deployment_manifest)   { "---\nname: something\ndirector_uuid: director-uuid" }
  let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
  let(:bosh_deploy_task_id)   { 123 }

  before do
    begin
      $etcd.delete("/actions", recursive: true)
    rescue Net::HTTPServerException
    end
  end


  it "has lifecycle" do
    action = Actions::CreateServiceInstance.new(service_id: service_id, service_instance_id: service_instance_id)
    service_klass = class_double('Service').as_stubbed_const
    service_klass.should_receive(:find_by_id).and_return(service)
    service.should_receive(:deployment_name_prefix).and_return(deployment_name_prefix)
    action.save

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/create_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => nil
    })

    ##
    ## Generate deployment manifest
    ##
    service.should_receive(:find_plan_by_id).and_return(service_plan)
    service.should_receive(:bosh_service_stub_paths).and_return(service_stub_paths)
    service_plan.should_receive(:deployment_stub).and_return(service_plan_stub)

    gds_klass = class_double('Generators::GenerateDeploymentStub').as_stubbed_const
    gds_klass.should_receive(:new).with({service: service, deployment_name: deployment_name}).and_return(stub_generator)
    expect(stub_generator).to receive(:generate).and_return(deployment_stub)

    gdm_klass = class_double("Generators::GenerateDeploymentManifest").as_stubbed_const
    gdm_klass.should_receive(:new).with({
      service_stub_paths: service_stub_paths,
      deployment_stub: deployment_stub,
      service_plan_stub: service_plan_stub
    }).and_return(manifest_generator)
    manifest_generator.should_receive(:generate_manifest).and_return(deployment_manifest)

    action.should_receive(:bosh_director_client).exactly(2).times.and_return(bosh_director_client)
    bosh_director_client.should_receive(:deploy).with(deployment_manifest).and_return([:running, bosh_deploy_task_id])
    bosh_director_client.should_receive(:track_task).with(bosh_deploy_task_id).and_return("done")

    action.perform

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/create_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => bosh_deploy_task_id
    })

  end
end
