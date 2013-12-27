require 'spec_helper'

describe BindingAttributes::JobIpAddress do
  let(:deployment_manifest) {
    <<-YAML
properties:
  service:
    port: 4001
    secret: some-secret
    YAML
  }
  let(:deployment_name) { 'deployment-name' }
  let(:service_id)      { 'service-id-1' }
  let(:service)         { instance_double('Service') }

  subject do
    BindingAttributes::JobIpAddress.new({
      service_id: service_id,
      deployment_manifest: deployment_manifest,
      deployment_name: deployment_name
    })
  end

  describe "extract IP address from deployment" do
    let(:vms_state) {
      [{'job_name'=>'master_job', 'index'=>0, 'ips'=>['10.244.2.6']},
       {'job_name'=>'other_job', 'index'=>0, 'ips'=>['10.244.2.254']}]
    }
    let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
    let(:service)               { instance_double("Service", bosh: bosh_director_client) }
    
    before {
      expect(class_double('Service').as_stubbed_const).to receive(:find_by_id).with(service_id).and_return(service)
      expect(bosh_director_client).to receive(:list_vms).with(deployment_name).and_return(vms_state)
    }

    it "find IP from deployment with explicit job_name/job_index" do
      subject.job_name = 'master_job'
      subject.job_index = 0
      expect(subject.value).to eq('10.244.2.6')
    end

    it "find IP from deployment with implicit job_index = 0" do
      subject.job_name = 'master_job'
      expect(subject.value).to eq('10.244.2.6')
    end

    it "return nil if job_name/job_index not found" do
      subject.job_name = 'unknown_job'
      expect(subject.value).to be_nil
    end
  end
end
