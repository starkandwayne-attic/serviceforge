require 'spec_helper'

describe 'the service lifecycle' do
  def cleanup_etcd_service(instance_id)
    delete "/v2/service_instances/#{instance_id}"
  rescue
  end

  let(:instance_id)     { 'instance-1' }
  let(:service_id)      { 'etcd-dedicated-id' }
  let(:plan_id) { '1-server-id' }

  # let(:binding_id) { 'binding-1' }
  # let(:binding)    { ServiceBinding.new(id: binding_id).username }

  before do
    cleanup_etcd_service(instance_id)
  end

  after do
    cleanup_etcd_service(instance_id)
  end

  it 'provisions, deprovisions' do
    ##
    ## Provision the instance
    ##
    put "/v2/service_instances/#{instance_id}", {
      "service_id" => service_id,
      "plan_id" => plan_id
    }

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    expect(instance).to eq({
      "id" => instance_id,
      "service_id" => service_id,
      "plan_id" => plan_id
    })

    ##
    ## Test the etcd entries
    ##
    data = JSON.parse($etcd.get("/service_instances/#{instance_id}").value)
    expect(data).to eq({
      "id" => instance_id, 
      "service_id" => service_id,
      "plan_id" => plan_id
    })

    ##
    ## Deprovision
    ##
    delete "/v2/service_instances/#{instance_id}"
    expect(response.status).to eq(200)

    ##
    ## Test that etcd entries no longer exist
    ##
    expect{ $etcd.get("/service_instances/#{instance_id}") }.to raise_error(Net::HTTPServerException)
  end
end
