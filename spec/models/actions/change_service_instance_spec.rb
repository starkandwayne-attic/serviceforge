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
      'deployment_name' => deployment_name
    })
  end
end
