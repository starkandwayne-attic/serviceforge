require 'spec_helper'

describe 'the service lifecycle' do
  let(:instance_id)  { 'instance-1' }
  let(:service_id)   { 'etcd-dedicated-id' }
  let(:plan_id)      { '1-server-id' }
  let(:binding_id)   { 'binding-1' }
  let(:app_guid)     { 'app-guid-1' }

  def cleanup_etcd_services
  rescue
  end

  before do
    begin
      $etcd.delete("/service_instances", recursive: true)
    rescue Net::HTTPServerException
    end
  end

  it 'provisions, deprovisions' do
    ##
    ## Provision the instance
    ##
    put "/v2/service_instances/#{instance_id}", {
      'service_id' => service_id,
      'plan_id' => plan_id
    }

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    expect(instance).to eq({
      "id" => instance_id,
      "service_id" => service_id,
      "plan_id" => plan_id
    })

    ##
    ## Test the etcd /service_instances entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{instance_id}/model").value)
    expect(data).to eq({
      'id' => instance_id, 
      'service_id' => service_id,
      'plan_id' => plan_id
    })

    ##
    ## Bind
    ##
    put "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}", {
      "plan_id" => plan_id,
      "service_id" => service_id,
      "app_guid" => app_guid,
      "service_instance_id" => instance_id,
      "id" => binding_id
    }

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    expect(instance.fetch('credentials')).to eq({
      'hostname' => '10.244.0.6',
      'host' => '10.244.0.6',
      'port' => 4001
    })

    ##
    ## Test the etcd /service_bindings entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{instance_id}/service_bindings/#{binding_id}/model").value)
    expect(data).to eq({
      'id' => binding_id,
      'service_instance_id' => instance_id,
      'credentials' => {
        'hostname' => '10.244.0.6',
        'host' => '10.244.0.6',
        'port' => 4001
      }
    })

    ##
    ## Unbind
    ##
    delete "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"
    expect(response.status).to eq(204)

    ##
    ## Deprovision
    ##
    delete "/v2/service_instances/#{instance_id}"
    expect(response.status).to eq(200)

    ##
    ## Test that etcd entries no longer exist
    ##
    expect{ $etcd.get("/service_instances/#{instance_id}/service_bindings/#{binding_id}/model") }.to raise_error(Net::HTTPServerException)
    expect{ $etcd.get("/service_instances/#{instance_id}/model") }.to raise_error(Net::HTTPServerException)
  end
end
