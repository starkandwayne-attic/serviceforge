require 'spec_helper'

describe 'the service lifecycle' do
  let(:seed) { RSpec.configuration.seed }
  let(:service_id)   { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated-bosh-lite
  let(:service)      { Service.find_by_id(service_id) }
  let(:plan_id)      { '5cfa57fc-1474-4eb9-9afb' } # 5-server
  let(:instance_id)  { "instance-#{seed}" }
  let(:binding_id)   { "binding-#{seed}" }
  let(:app_guid)     { "app-guid-#{seed}" }
  let(:deployment_name) { "test-etcd-#{instance_id}" }

  def cleanup_etcd_service_instances
    $etcd.delete("/service_instances", recursive: true)
  rescue Net::HTTPServerException
  end

  def cleanup_bosh_deployments
    Service.all.each do |service|
      delete_task_ids = []
      service.bosh.list_deployments.each do |deployment|
        if deployment["name"] =~ /^#{service.deployment_name_prefix}\-/
          _, bosh_task_id = service.bosh.delete(deployment["name"])
          delete_task_ids << bosh_task_id
        end
      end
      service.bosh.wait_for_tasks_to_complete(delete_task_ids)
    end
  end

  before do
    cleanup_etcd_service_instances
    cleanup_bosh_deployments
  end

  after do
    cleanup_etcd_service_instances
    cleanup_bosh_deployments
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
      'id' => instance_id,
      'service_id' => service_id,
      'plan_id' => plan_id,
      'deployment_name' => deployment_name
    })

    ##
    ## Test the etcd /service_instances entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{instance_id}/model").value)
    expect(data).to eq({
      'id' => instance_id, 
      'service_id' => service_id,
      'plan_id' => plan_id,
      'deployment_name' => deployment_name
    })

    ##
    ## Test bosh for deployment entry
    ##
    deployment_exists = service.bosh.deployment_exists?(deployment_name)
    expect(deployment_exists).to_not be_nil

    vms = service.bosh.list_vms(deployment_name)
    expect(vms.size).to eq(5)

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
      'hostname' => '10.244.2.6',
      'host' => '10.244.2.6',
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
        'hostname' => '10.244.2.6',
        'host' => '10.244.2.6',
        'port' => 4001
      }
    })

    ##
    ## Test the etcd /actions/update_service_bindings record
    ##
    data = JSON.parse($etcd.get("/actions/update_service_binding/#{binding_id}").value)
    expect(data).to_not be_nil

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

    ##
    ## Test deployment entry no longer exists
    ##
    deployment_exists = service.bosh.deployment_exists?(deployment_name)
    expect(deployment_exists).to be_false

  end
end
