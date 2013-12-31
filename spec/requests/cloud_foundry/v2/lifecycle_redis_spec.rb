require 'spec_helper'

describe 'redis service - lifecycle' do
  let(:seed)                { RSpec.configuration.seed }
  let(:service_id)          { '1683fe81-b492-4e92-8282-0cdca7c316e1' } # redis-dedicated-bosh-lite
  let(:service)             { Service.find_by_id(service_id) }
  let(:two_server_plan_id)  { 'e23b4ad6-d33f-4764-803b-d507bb0b95d1' }
  let(:three_server_plan_id) { '1a6ee012-a591-4d7f-99ae-7ff4af1e240a' }
  let(:service_plan_id)     { three_server_plan_id }
  let(:service_instance_id) { "instance-#{seed}" }
  let(:service_binding_id)  { "binding-#{seed}" }
  let(:app_guid)            { "app-guid-#{seed}" }
  let(:deployment_name)     { "test-redis-#{service_instance_id}" }

  def cleanup_redis_service_instances
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
    cleanup_redis_service_instances
    cleanup_bosh_deployments
  end

  after do
    cleanup_redis_service_instances
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
    expect(service_instance).to eq({})

    ##
    ## Test the redis /service_instances entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
    expect(data).to eq({
      'service_instance_id' => service_instance_id, 
      'service_id' => service_id,
      'service_plan_id' => three_server_plan_id,
      'deployment_name' => deployment_name
    })

    ##
    ## Test bosh for deployment entry
    ##
    deployment_exists = service.bosh.deployment_exists?(deployment_name)
    expect(deployment_exists).to_not be_nil

    vms = service.bosh.list_vms(deployment_name)
    expect(vms.size).to eq(3)

    ##
    ## Cloud Controller binds the service instance to an app
    ##
    put "/v2/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}", {
      "plan_id" => service_plan_id,
      "service_id" => service_id,
      "app_guid" => app_guid,
      "instance_id" => service_instance_id,
      "id" => service_binding_id
    }

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    ##
    ## Test the redis /service_bindings entry
    ##
    data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model").value)

    # TODO still working on implementation of BindingCommands
    binding_commands = data.fetch('credentials').delete('binding_commands')

    expect(data).to eq({
      'service_binding_id' => service_binding_id,
      'service_instance_id' => service_instance_id,
      'credentials' => {
        'host' => '10.244.2.6',
        'port' => 4001
      }
    })


    p instance
    credentials = instance.fetch('credentials')
    binding_commands = credentials.delete('binding_commands')
    expect(credentials).to eq({
      'host' => '10.244.2.6',
      'port' => 4001
    })

    # 'binding_commands' => {
    #   'commands' => {
    #     'vms_state' => { 'method' => 'GET', 'url' => "http://broker-address/binding_commands/CMD_AUTH_TOKEN" }
    #   }
    # }

    vms_state_cmd = binding_commands.fetch('commands').fetch('vms-state')
    expect(vms_state_cmd).to_not be_nil
    expect(vms_state_cmd['method']).to eq('GET')

    # GET is required for this binding_command, so PUT should fail with 405
    put URI.parse(vms_state_cmd['url']).path
    expect(response.status).to eq(405)

    # Now try GET as required...
    get URI.parse(vms_state_cmd['url']).path
    expect(response.status).to eq(200)
    vms_state = JSON.parse(response.body)
    expect(vms_state.size).to eq(3) # one for each VM in 5-servers cluster

    # 'binding_commands' => {
    #   'current_plan' => current_plan_label,
    #   'commands' => {
    #     '1-server'  => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/AUTH_TOKEN" },
    #     '3-servers' => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/OTHER_TOKEN" },
    #   }
    # }
    # expect(binding_commands.fetch('current_plan')).to eq('5-servers') # see let(:plan_id)
    # commands = binding_commands.fetch('commands')
    # expect(commands).to be_instance_of(Hash)
    # 
    # three_server_plan_url = commands.fetch('3-servers').fetch('url')
    # three_server_plan_method = commands.fetch('3-servers').fetch('method')
    # 
    # # Trigger downgrade to 1-server plan
    # expect(three_server_plan_method).to eq('PUT')
    # put URI.parse(three_server_plan_url).path, {}

    # TODO implement creation & invocation of BindingCommands
    # expect(response.status).to eq(200)

    ##
    ## Test the redis /service_instances entry
    ##
    # data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
    # expect(data).to eq({
    #   'service_instance_id' => service_instance_id,
    #   'service_id' => service_id,
    #   'service_plan_id' => two_server_plan_id,
    #   'deployment_name' => deployment_name
    # })

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
    ## Test that redis entries no longer exist
    ##
    expect{ $etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model") }.to raise_error(Net::HTTPServerException)
    expect{ $etcd.get("/service_instances/#{service_instance_id}/model") }.to raise_error(Net::HTTPServerException)

    ##
    ## Test deployment entry no longer exists
    ##
    deployment_exists = service.bosh.deployment_exists?(deployment_name)
    expect(deployment_exists).to be_false

  end
end
