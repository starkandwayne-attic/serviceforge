require 'spec_helper'

describe V2::ServiceBindingsController do
  let(:service)         { instance_double('Service') }
  let(:service_id)      { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated-bosh-lite
  let(:instance_klass)  { class_double('ServiceInstance').as_stubbed_const }
  let(:instance_id)     { 'instance-1' }
  let(:deployment_name) { 'deployment-name' }
  let(:instance)        { instance_double('ServiceInstance', id: instance_id, service_id: service_id, deployment_name: deployment_name) }

  before do
    authenticate
  end

  describe '#update' do
    let(:binding_id) { 'binding-123' }
    let(:binding_klass) { class_double('ServiceBinding').as_stubbed_const }
    let(:binding)    { instance_double('ServiceBinding') }
    let(:prepare_klass)  { class_double('Actions::PrepareServiceBinding').as_stubbed_const }
    let(:prepare)        { instance_double('Actions::PrepareServiceBinding') }
    let(:cbc_klass)  { class_double('Actions::CreateBindingCommands').as_stubbed_const }
    let(:cbc)        { instance_double('Actions::CreateBindingCommands') }

    it "prepares binding & creates binding commands" do
      expect(instance_klass).to receive(:find_by_id).with(instance_id).and_return(instance)
      # expect(instance).to receive(:service_id).and_return()
      expect(binding_klass).to receive(:new).with(id: binding_id, service_instance: instance).and_return(binding)
      expect(binding).to receive(:save)

      prepare_klass.should_receive(:new).with({
        service_id: service_id,
        service_binding_id: binding_id,
        deployment_name: deployment_name
      }).and_return(prepare)
      expect(prepare).to receive(:perform)

      cbc_klass.should_receive(:new).with({
        service_id: service_id,
        service_instance_id: instance_id,
        service_binding_id: binding_id,
        deployment_name: deployment_name
      }).and_return(cbc)
      expect(cbc).to receive(:save)
      expect(cbc).to receive(:perform)

      put :update, id: binding_id, service_instance_id: instance_id
    end
  end
end
