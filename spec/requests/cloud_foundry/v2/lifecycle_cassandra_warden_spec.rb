require 'spec_helper'

describe 'cassandra service - lifecycle on warden' do
  let(:seed)                { RSpec.configuration.seed }
  let(:service_id)          { '4d1cab61-09ff-4442-a8e7-d270459bd025' } # cassandra-dedicated   
  let(:service)             { Service.find_by_id(service_id) }
  let(:three_server_plan_id) { '4ca347c2-f4da-4d76-8536-f7e0b589c8a2' }
  let(:five_server_plan_id) { '069f3fd0-560d-43a5-840d-3b8aca9e63c2' }
  let(:service_plan_id)     { five_server_plan_id }
  let(:service_instance_id) { "instance-#{seed}" }
  let(:service_binding_id)  { "binding-#{seed}" }
  let(:app_guid)            { "app-guid-#{seed}" }
  let(:deployment_name)     { "test-cassandra-#{service_instance_id}" }

  def cleanup_cassandra_service_instances
    $etcd.delete("/service_instances", recursive: true)
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
      # TODO queued tasks are being ignored; can they be cancelled or waited upon to finish?
      director_client.wait_for_tasks_to_complete(delete_task_ids)
      director_client.reset_infrastructure_network_for_testing
    end
  end

  before do
    cleanup_cassandra_service_instances
    cleanup_bosh_deployments
  end

  after do
    cleanup_cassandra_service_instances
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
    expect(response.status).to eq(200)
    dashboard_root = JSON.parse(response.body)
    expect(dashboard_root["state"]).to eq("deploying")

    ##
    ## Test the cassandra /service_instances entry
    ## Note: state = deploying
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
    data['infrastructure_network'].delete('template') # different for each machine
    latest_bosh_deployment_task_id = data.delete('latest_bosh_deployment_task_id') # different for each test
    expect(data).to eq({
      'service_instance_id' => service_instance_id, 
      'service_id' => service_id,
      'service_plan_id' => five_server_plan_id,
      'deployment_name' => deployment_name,
      'infrastructure_network' => { 'ip_range_start' => '10.244.2.0' },
      'state' => 'deploying'
    })

    ##
    ## Cloud Controller binds the service instance to an app
    ## BUT the deployment is still going so binding fails
    ##
    put "/v2/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}", {
      "plan_id" => service_plan_id,
      "service_id" => service_id,
      "app_guid" => app_guid,
      "instance_id" => service_instance_id,
      "id" => service_binding_id
    }

    expect(response.status).to eq(403) # Forbidden because its not ready

    ##
    ## Cloud Controller binds the service instance to an app, with
    ## blocking until service instance is ready for binding
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
    ## Test the cassandra /service_instances entry
    ## Note: state = running
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
    data['infrastructure_network'].delete('template') # different for each machine
    latest_bosh_deployment_task_id = data.delete('latest_bosh_deployment_task_id') # different for each test
    expect(data).to eq({
      'service_instance_id' => service_instance_id, 
      'service_id' => service_id,
      'service_plan_id' => five_server_plan_id,
      'deployment_name' => deployment_name,
      'infrastructure_network' => { 'ip_range_start' => '10.244.2.0' },
      'state' => 'running'
    })

    ##
    ## Test the cassandra /service_bindings entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model").value)

    expect(data['credentials']['hosts']).to_not be_nil
    data['credentials']['hosts'].sort!
    expect(data).to eq({
      'service_binding_id' => service_binding_id,
      'service_instance_id' => service_instance_id,
      'credentials' => {
        'hosts' => ['10.244.2.10', '10.244.2.14', '10.244.2.18', '10.244.2.2', '10.244.2.6'],
        'port' => 7000
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
    ## Test that cassandra entries no longer exist
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
