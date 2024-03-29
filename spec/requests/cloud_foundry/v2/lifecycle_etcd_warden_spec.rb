require 'spec_helper'

describe 'etcd service - lifecycle on warden' do
  let(:seed)                { RSpec.configuration.seed }
  let(:service_id)          { 'b9698740-4810-4dc5-8da6-54581f5108c4' } # etcd-dedicated   
  let(:service)             { Service.find_by_id(service_id) }
  let(:three_server_plan_id) { '1a448d0e-bc54-4a16-8d2f-ab701be20c40' }
  let(:five_server_plan_id)  { '5cfa57fc-1474-4eb9-9afb' }
  let(:service_plan_id)     { five_server_plan_id }
  let(:service_instance_id) { "instance-#{seed}" }
  let(:service_binding_id)  { "binding-#{seed}" }
  let(:app_guid)            { "app-guid-#{seed}" }
  let(:deployment_name)     { "test-etcd-#{service_instance_id}" }

  def cleanup_etcd
    $etcd.delete("/service_instances", recursive: true)
    $etcd.delete("/binding_commands", recursive: true)
    $etcd.delete("/registered_binding_commands", recursive: true)
  rescue Net::HTTPServerException
  end

  def cleanup_bosh_deployments
    Bosh::DirectorClient.available_director_clients.each do |director_client|
      delete_task_ids = []
      director_client.list_deployments.each do |deployment|
        if deployment["name"] =~ /^#{service.deployment_name_prefix}\-/
          _, bosh_task_id = service.director_client.delete(deployment["name"])
          delete_task_ids << bosh_task_id
        end
      end
      director_client.wait_for_tasks_to_complete(delete_task_ids)
      director_client.reset_infrastructure_network_for_testing
    end
  end

  before do
    cleanup_etcd
    cleanup_bosh_deployments
  end

  after do
    cleanup_etcd
    cleanup_bosh_deployments
  end

  it 'provisions, deprovisions' do
    ##
    ## Cloud Controller provisions the service instance
    ##
    put "/v2/service_instances/#{service_instance_id}", {
      'service_id' => service_id,
      'plan_id' => service_plan_id
    }

    expect(response.status).to eq(201)
    service_instance = JSON.parse(response.body)
    dashboard_url = service_instance.delete("dashboard_url")
    expect(service_instance).to eq({})

    ##
    ## Test dashboard_url
    ##

    expect(dashboard_url).to_not be_nil
    dashboard_uri = URI.parse(dashboard_url)
    dashboard_uri.host = dashboard_uri.scheme = dashboard_uri.port = dashboard_uri.user = dashboard_uri.password = nil

    get dashboard_uri

    ##
    ## Test the etcd /service_instances entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
    data['infrastructure_network'].delete('template') # different for each machine
    latest_bosh_deployment_task_id = data.delete('latest_bosh_deployment_task_id') # different for each test
    expect(data).to eq({
      'service_instance_id' => service_instance_id, 
      'service_id' => service_id,
      'service_plan_id' => five_server_plan_id,
      'deployment_name' => deployment_name,
      'infrastructure_network' => {"ip_range_start"=>"10.244.2.0"},
      'state' => 'deploying'
    })

    ##
    ## Cloud Controller binds the service instance to an app
    ##
    ## "wait_til_ready" => true is useful for testing; is not part of CF API
    ##
    put "/v2/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}", {
      "plan_id" => service_plan_id,
      "service_id" => service_id,
      "app_guid" => app_guid,
      "instance_id" => service_instance_id,
      "id" => service_binding_id,
      "wait_til_ready" => true
    }

    expect(response.status).to eq(201)
    binding = JSON.parse(response.body)
    p binding

    ##
    ## Test bosh for deployment entry
    ##
    deployment_exists = service.director_client.deployment_exists?(deployment_name)
    expect(deployment_exists).to_not be_nil

    vms = service.director_client.list_vms(deployment_name)
    expect(vms.size).to eq(5)

    ##
    ## Test the etcd /service_bindings entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model").value)

    expect(data).to eq({
      'service_binding_id' => service_binding_id,
      'service_instance_id' => service_instance_id,
      'credentials' => {
        'host' => '10.244.2.2',
        'port' => 4001
      }
    })



    ##
    ## Unbind
    ##
    delete "/v2/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}"
    expect(response.status).to eq(204)

    ##
    ## Deprovision
    ##
    delete "/v2/service_instances/#{service_instance_id}"
    expect(response.status).to eq(200)

    ##
    ## Test that etcd entries no longer exist
    ##
    expect{ $etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model") }.to raise_error(Net::HTTPServerException)
    expect{ $etcd.get("/service_instances/#{service_instance_id}/model") }.to raise_error(Net::HTTPServerException)

    ##
    ## Test deployment entry no longer exists
    ##
    deployment_exists = service.director_client.deployment_exists?(deployment_name)
    expect(deployment_exists).to be_false

  end
end
