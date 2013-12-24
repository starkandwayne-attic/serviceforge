require 'spec_helper'

describe V2::ServiceBindingsController do
  let(:service)         { instance_double('Service') }
  let(:service_id)      { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated-bosh-lite
  let(:instance_klass)  { class_double('ServiceInstance').as_stubbed_const }
  let(:instance)        { instance_double('ServiceInstance') }
  let(:instance_id)     { 'instance-1' }
  let(:deployment_name) { 'deployment-name' }
  let(:instance)        { ServiceInstance.new(id: instance_id, service_id: service_id, deployment_name: deployment_name) }

  before do
    authenticate
    instance.save
  end

  after { instance.destroy }

  describe '#update' do
    let(:binding_id) { 'binding-123' }
    let(:action_klass) { class_double('Actions::UpdateServiceBinding').as_stubbed_const }
    let(:action)     { instance_double('Actions::UpdateServiceBinding') }
    let(:master_host_job_name) { 'etcd_leader_z1' }
    let(:master_host_address)  { '10.1.2.3' }

    it "fetches master_host_address from bosh deployment" do
      expect(instance_klass).to receive(:find_by_id).with(instance_id).and_return(instance)
      action_klass.should_receive(:new).with({
        service_id: service_id,
        service_binding_id: binding_id,
        deployment_name: deployment_name,
        master_host_job_name: master_host_job_name
      }).and_return(action)
      expect(action).to receive(:save)
      expect(action).to receive(:perform)
      expect(action).to receive(:master_host_address).and_return(master_host_address)

      put :update, id: binding_id, service_instance_id: instance_id
    end
  end
end
