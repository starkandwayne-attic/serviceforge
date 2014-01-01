require 'spec_helper'

describe Actions::ChangeServiceInstance do
  let(:stub_generator)        { instance_double("Generators::GenerateDeploymentStub") }
  let(:manifest_generator)    { instance_double("Generators::GenerateDeploymentManifest") }
  let(:service)               { instance_double("Service") }
  let(:service_id)            { 'service-id-1' }
  let(:service_plan_id)       { 'service-plan-id-1' }
  let(:service_plan)          { instance_double("Plan") }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_stub_paths)    { %w[/path/to/file1.yml /path/to/file2.yml] }
  let(:deployment_stub)       { "---\nname: something" }
  let(:service_plan_stub)     { "---\njobs:\n  - name: etc\n  - instances: 2" }
  let(:director_uuid)         { "director-uuid" }
  let(:deployment_name)       { 'deployment-name' }
  let(:deployment_manifest)   { "---\nname: deployment-name\ndirector_uuid: director-uuid" }
  let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
  let(:bosh_deploy_task_id)   { 123 }

  before do
    begin
      $etcd.delete("/actions", recursive: true)
    rescue Net::HTTPServerException
    end
  end

  it "generates new deployment manifest and deploys it" do
    # service_klass = class_double('Service').as_stubbed_const
    # expect(service_klass).to receive(:find_by_id).and_return(service)
    action = Actions::ChangeServiceInstance.create(
      service_id: service_id, service_instance_id: service_instance_id, service_plan_id: service_plan_id, deployment_name: deployment_name)

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/change_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_plan_id' => service_plan_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => nil
    })

    ##
    ## Generate deployment manifest
    ##
    expect(class_double('Service').as_stubbed_const).to receive(:find_by_id).and_return(service)
    expect(service).to receive(:find_plan_by_id).and_return(service_plan)
    expect(service).to receive(:bosh_service_stub_paths).and_return(service_stub_paths)
    expect(service_plan).to receive(:bosh_deployment_stub_yaml).and_return(service_plan_stub)

    gds_klass = class_double('Generators::GenerateDeploymentStub').as_stubbed_const
    expect(gds_klass).to receive(:new).with({service: service, deployment_name: deployment_name}).and_return(stub_generator)
    expect(stub_generator).to receive(:generate).and_return(deployment_stub)

    gdm_klass = class_double("Generators::GenerateDeploymentManifest").as_stubbed_const
    expect(gdm_klass).to receive(:new).with({
      service_stub_paths: service_stub_paths,
      deployment_stub: deployment_stub,
      service_plan_stub: service_plan_stub
    }).and_return(manifest_generator)
    expect(manifest_generator).to receive(:generate_manifest).and_return(deployment_manifest)

    expect(action).to receive(:bosh_director_client).exactly(2).times.and_return(bosh_director_client)
    expect(bosh_director_client).to receive(:deploy).with(deployment_manifest).and_return([:running, bosh_deploy_task_id])
    expect(bosh_director_client).to receive(:track_task).with(bosh_deploy_task_id).and_return("done")

    action.perform

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/change_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_plan_id' => service_plan_id,
      'service_instance_id' => service_instance_id,
      'deployment_name' => deployment_name,
      'bosh_task_id' => bosh_deploy_task_id
    })
  end

end
