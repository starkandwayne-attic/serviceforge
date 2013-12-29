require 'spec_helper'

describe BindingCommands::Bosh::DeploymentVmState do
  let(:service_id) { 'service-id-1' }
  let(:deployment_name) { 'deployment-name' }
  let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
  let(:vms_state) {
    [{'job_name'=>'master_job', 'index'=>0, 'ips'=>['10.244.2.6']},
     {'job_name'=>'other_job', 'index'=>0, 'ips'=>['10.244.2.254']}]
  }

  subject { BindingCommands::Bosh::DeploymentVmState.new({
    service_id: service_id,
    deployment_name: deployment_name
  })}

  it "returns state of each VM in service_instance deployment" do
    expect(subject).to receive(:bosh_director_client).and_return(bosh_director_client)
    expect(bosh_director_client).to receive(:fetch_vm_state).with(deployment_name).and_return([vms_state, 'some-task-id'])

    subject.perform
    expect(subject.to_json).to eq(vms_state.to_json)
  end
end
