require 'spec_helper'

describe ServiceInstancesController do
  let(:service)             { instance_double('Service') }
  let(:service_id)          { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated   
  let(:service_instance_id) { 'instance-1' }
  let(:deployment_name)     { 'deployment-name' }
  let(:service_instance)    { instance_double('ServiceInstance', service_instance_id: service_instance_id, service_id: service_id, deployment_name: deployment_name) }
  let(:update)        { instance_double('Actions::UpdateServiceInstanceState') }

  before do
    authenticate
    expect(class_double('ServiceInstance').as_stubbed_const).to receive(:find_by_id).with(service_instance_id).at_least(1).times.and_return(service_instance)
  end

  describe "GET 'show'" do
    it "returns http success" do
      expect(class_double('Actions::UpdateServiceInstanceState').as_stubbed_const).to receive(:new).with({
        service_id: service_id,
        service_instance_id: service_instance_id
      }).and_return(update)
      expect(update).to receive(:perform)

      get 'show', id: service_instance_id
      response.should be_success
    end
  end

end
