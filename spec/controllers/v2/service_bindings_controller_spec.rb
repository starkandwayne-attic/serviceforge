require 'spec_helper'

describe V2::ServiceBindingsController do
  let(:service)         { instance_double('Service') }
  let(:service_id)      { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated-bosh-lite
  let(:instance_klass)  { class_double('ServiceInstance').as_stubbed_const }
  let(:service_instance_id) { 'instance-1' }
  let(:deployment_name) { 'deployment-name' }
  let(:service_instance)        { instance_double('ServiceInstance', service_instance_id: service_instance_id, service_id: service_id, deployment_name: deployment_name) }

  before do
    authenticate
  end

  describe '#update' do
    let(:service_binding_id)    { 'binding-123' }
    let(:service_binding_klass) { class_double('ServiceBinding').as_stubbed_const }
    let(:service_binding)       { instance_double('ServiceBinding') }
    let(:prepare_klass) { class_double('Actions::PrepareServiceBinding').as_stubbed_const }
    let(:prepare)       { instance_double('Actions::PrepareServiceBinding') }
    let(:cbc_klass)     { class_double('Actions::CreateBindingCommands').as_stubbed_const }
    let(:cbc)           { instance_double('Actions::CreateBindingCommands') }

    it "prepares binding & creates binding commands" do
      expect(instance_klass).to receive(:find_by_id).with(service_instance_id).and_return(service_instance)
      expect(service_binding_klass).to receive(:create).
        with(service_binding_id: service_binding_id, service_instance_id: service_instance_id).
        and_return(service_binding)
      expect(service_binding_klass).to receive(:find_by_instance_id_and_binding_id).
        with(service_instance_id, service_binding_id).
        and_return(service_binding)

      prepare_klass.should_receive(:new).with({
        service_id: service_id,
        service_instance_id: service_instance_id,
        service_binding_id: service_binding_id,
        deployment_name: deployment_name
      }).and_return(prepare)
      expect(prepare).to receive(:perform)

      cbc_klass.should_receive(:new).with({
        service_id: service_id,
        service_instance_id: service_instance_id,
        service_binding_id: service_binding_id,
        deployment_name: deployment_name
      }).and_return(cbc)
      expect(cbc).to receive(:save)
      expect(cbc).to receive(:perform)

      put :update, id: service_binding_id, service_instance_id: service_instance_id
    end
  end
end
