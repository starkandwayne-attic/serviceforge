require 'spec_helper'

describe Actions::WaitForServiceInstanceDeployment do
  let(:service_id)          { 'service-id' }
  let(:service_instance_id) { 'instance-id' }
  let(:service_instance)    { instance_double('ServiceInstance') }

  subject { Actions::WaitForServiceInstanceDeployment.new(service_id: service_id, service_instance_id: service_instance_id) }

  before { expect(subject).to receive(:service_instance).at_least(1).times.and_return(service_instance) }

  context "ServiceInstance was already running or generally not deploying" do
    it "does nothing" do
      expect(service_instance).to receive(:deploying?).and_return(false)
      subject.perform
    end
  end

  context "ServiceInstance was deploying" do
    let(:director_client) { instance_double('Bosh::DirectorClient') }
    let(:task_id)         { 123 }

    before{
      expect(service_instance).to receive(:deploying?).and_return(true)
      expect(service_instance).to receive(:latest_bosh_deployment_task_id).twice.and_return(task_id)
      expect(subject).to receive(:bosh_director_client).and_return(director_client)
    }

    it "does checks latest BOSH task status, and is now running" do
      expect(director_client).to receive(:track_task).with(task_id).and_return(:done)
      expect(service_instance).to receive(:deployment_successful!)

      subject.perform
    end

    it "does checks latest BOSH task status, and is still deploying" do
      expect(director_client).to receive(:track_task).with(task_id).and_return(:running)
      expect(service_instance).to receive(:deploying!)

      subject.perform
    end

    it "does checks latest BOSH task status, and deployment failed" do
      expect(director_client).to receive(:track_task).with(task_id).and_return(:failed)
      expect(service_instance).to receive(:failed_deployment!)

      subject.perform
    end
  end
end
