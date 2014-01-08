require 'spec_helper'

describe V2::ServiceBindingsController do
  let(:service_binding_id)  { 'binding-123' }
  let(:service)             { instance_double('Service') }
  let(:service_id)          { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated-bosh-lite
  let(:instance_klass)      { class_double('ServiceInstance').as_stubbed_const }
  let(:service_instance_id) { 'instance-1' }
  let(:deployment_name)     { 'deployment-name' }
  let(:service_instance)    { instance_double('ServiceInstance', service_instance_id: service_instance_id, service_id: service_id, deployment_name: deployment_name) }
  let(:request_base_url)    { 'http://127.0.0.1:6000' }

  before do
    authenticate
    expect(instance_klass).to receive(:find_by_id).with(service_instance_id).at_least(1).times.and_return(service_instance)
  end

  context "ServiceInstance ready for binding" do
    describe '#update' do
      let(:service_binding_klass) { class_double('ServiceBinding').as_stubbed_const }
      let(:service_binding)       { instance_double('ServiceBinding') }
      let(:prepare)       { instance_double('Actions::PrepareServiceBinding') }
      let(:cbc)           { instance_double('Actions::CreateBindingCommands') }

      it "prepares binding & creates binding commands" do
        expect(service_instance).to receive(:running?).and_return(true)

        expect(service_binding_klass).to receive(:create).
          with(service_binding_id: service_binding_id, service_instance_id: service_instance_id).
          and_return(service_binding)
        expect(service_binding_klass).to receive(:find_by_instance_id_and_binding_id).
          with(service_instance_id, service_binding_id).
          and_return(service_binding)


        expect(class_double('Actions::PrepareServiceBinding').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id,
          service_binding_id: service_binding_id,
          deployment_name: deployment_name
        }).and_return(prepare)
        expect(prepare).to receive(:perform)

        expect(class_double('Actions::CreateBindingCommands').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id,
          service_binding_id: service_binding_id,
          deployment_name: deployment_name,
          request_base_url: request_base_url
        }).and_return(cbc)
        expect(cbc).to receive(:perform)

        put :update, id: service_binding_id, service_instance_id: service_instance_id

        expect(response.status).to eq(201)
      end
    end
  end

  context "ServiceInstance not yet ready for binding" do
    let(:update)        { instance_double('Actions::UpdateServiceInstanceState') }

    describe '#update' do
      it "prepares binding & creates binding commands" do
        expect(service_instance).to receive(:running?).and_return(false)

        expect(class_double('Actions::UpdateServiceInstanceState').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id
        }).and_return(update)
        expect(update).to receive(:perform)

        expect(service_instance).to receive(:running?).and_return(false)

        put :update, id: service_binding_id, service_instance_id: service_instance_id

        expect(response.status).to eq(403)
      end
    end

    describe "#update with wait_til_ready=true" do
      let(:service_binding_klass) { class_double('ServiceBinding').as_stubbed_const }
      let(:service_binding)       { instance_double('ServiceBinding') }
      let(:prepare)       { instance_double('Actions::PrepareServiceBinding') }
      let(:cbc)           { instance_double('Actions::CreateBindingCommands') }

      it "waits until BOSH deployment complete then starts CreateServiceBinding" do
        expect(service_instance).to receive(:running?).and_return(false)

        expect(class_double('Actions::WaitForServiceInstanceDeployment').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id
        }).and_return(update)
        expect(update).to receive(:perform)

        expect(service_instance).to receive(:running?).and_return(true)

        expect(service_binding_klass).to receive(:create).
          with(service_binding_id: service_binding_id, service_instance_id: service_instance_id).
          and_return(service_binding)
        expect(service_binding_klass).to receive(:find_by_instance_id_and_binding_id).
          with(service_instance_id, service_binding_id).
          and_return(service_binding)


        expect(class_double('Actions::PrepareServiceBinding').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id,
          service_binding_id: service_binding_id,
          deployment_name: deployment_name
        }).and_return(prepare)
        expect(prepare).to receive(:perform)

        expect(class_double('Actions::CreateBindingCommands').as_stubbed_const).to receive(:new).with({
          service_id: service_id,
          service_instance_id: service_instance_id,
          service_binding_id: service_binding_id,
          deployment_name: deployment_name,
          request_base_url: request_base_url
        }).and_return(cbc)
        expect(cbc).to receive(:perform)

        put :update, id: service_binding_id, service_instance_id: service_instance_id, wait_til_ready: true

        expect(response.status).to eq(201)
      end
    end
  end
end
