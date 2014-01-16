require 'spec_helper'

describe Actions::WaitForServiceInstanceDeletion do
  let(:service_id)          { 'service-id' }
  let(:service_instance_id) { 'instance-id' }
  let(:service_instance)    { instance_double('ServiceInstance') }

  subject { Actions::WaitForServiceInstanceDeletion.new(service_id: service_id, service_instance_id: service_instance_id) }

  before { expect(subject).to receive(:service_instance).at_least(1).times.and_return(service_instance) }

  context "ServiceInstance was not being deleted/destroyed" do
    it "does nothing" do
      expect(service_instance).to receive(:destroying?).and_return(false)
      subject.perform
    end
  end

  context "ServiceInstance was being deleted/destroyed" do
    let(:bosh_director_client) { instance_double('Bosh::DirectorClient') }
    let(:task_id)         { 123 }
    let(:infrastructure_network){ instance_double('Bosh::InfrastructureNetwork') }

    before{
      expect(service_instance).to receive(:destroying?).and_return(true)
      expect(service_instance).to receive(:latest_bosh_deployment_task_id).twice.and_return(task_id)
      expect(subject).to receive(:bosh_director_client).at_least(1).times.and_return(bosh_director_client)
    }

    it "does checks latest BOSH task status, and is now destroyed" do
      expect(bosh_director_client).to receive(:track_task).with(task_id).and_return(:done)
      expect(bosh_director_client).to receive(:release_infrastructure_network).with(infrastructure_network)
      expect(service_instance).to receive(:deletion_successful!)
      expect(service_instance).to receive(:infrastructure_network).and_return(infrastructure_network)

      subject.perform
    end

    it "does checks latest BOSH task status, and is still running bosh deployment" do
      expect(bosh_director_client).to receive(:track_task).with(task_id).and_return(:running)
      expect(service_instance).to receive(:deploying!)

      subject.perform
    end

    it "does checks latest BOSH task status, and deployment failed" do
      expect(bosh_director_client).to receive(:track_task).with(task_id).and_return(:failed)
      expect(service_instance).to receive(:deletion_failed!)

      subject.perform
    end
  end
end
