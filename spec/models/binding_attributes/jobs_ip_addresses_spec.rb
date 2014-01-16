require 'spec_helper'

describe BindingAttributes::JobsIpAddresses do
  let(:deployment_manifest) { "--- {}" }
  let(:deployment_name) { 'deployment-name' }
  let(:service_id)      { 'service-id-1' }
  let(:service)         { instance_double('Service') }

  subject do
    BindingAttributes::JobsIpAddresses.new({
      service_id: service_id,
      deployment_manifest: deployment_manifest,
      deployment_name: deployment_name
    })
  end

  describe "extract IP addresses from selected jobs of deployment" do
    let(:vms_state) {
      [
        {'job_name'=>'master_job', 'index'=>0, 'ips'=>['10.244.2.6']},
        {'job_name'=>'master_job', 'index'=>1, 'ips'=>['10.244.2.10']},
        {'job_name'=>'secondary_job', 'index'=>0, 'ips'=>['10.244.2.14']},
        {'job_name'=>'other_job', 'index'=>0, 'ips'=>['10.244.2.254']}
      ]
    }
    let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
    let(:service)               { instance_double("Service", director_client: bosh_director_client) }

    before {
      expect(class_double('Service').as_stubbed_const).to receive(:find_by_id).with(service_id).and_return(service)
      expect(bosh_director_client).to receive(:fetch_vm_state).with(deployment_name).and_return([vms_state, 'some-task-id'])
    }

    it "returns the IPs for the VMs for the requested job_names" do
      subject.job_names = ['master_job', 'secondary_job']
      expect(subject.value).to eq(['10.244.2.6', '10.244.2.10', '10.244.2.14'])
    end

  end
end
