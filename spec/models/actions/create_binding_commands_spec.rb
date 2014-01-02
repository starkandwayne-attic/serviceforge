require 'spec_helper'

describe Actions::CreateBindingCommands do
  let(:service_id)      { '1683fe81-b492-4e92-8282-0cdca7c316e1' } # redis-dedicated-bosh-lite
  let(:service_plan_id) { 'e23b4ad6-d33f-4764-803b-d507bb0b95d1' } # 2-servers
  let(:service)         { Service.find_by_id(service_id) }

  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:service_instance)      { instance_double('ServiceInstance') }
  let(:service_binding)       { instance_double('ServiceBinding') }
  let(:deployment_name)       { 'deployment-name' }
  let(:credentials)           { instance_double('Hash') }
  let(:uuid)                  { instance_double('UUID') }
  let(:vms_state_uuid)        { 'vms_state_uuid' }
  let(:scale_1_server_uuid)   { 'scale_1_server_uuid' }
  let(:scale_2_servers_uuid)  { 'scale_2_servers_uuid' }
  let(:scale_3_servers_uuid)  { 'scale_3_servers_uuid' }
  let(:request_base_url)      { 'http://broker-address' }
  let(:expected_binding_commands) {
    {
      'current_plan' => '2-servers', 
      'commands' => {
        'vms-state' => { 'method' => 'GET', 'url' => "http://broker-address/binding_commands/#{vms_state_uuid}" },
        '1-server'  => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/#{scale_1_server_uuid}" },
        '2-servers' => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/#{scale_2_servers_uuid}" },
        '3-servers' => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/#{scale_3_servers_uuid}" },
      }
    }
  }

  subject { Actions::CreateBindingCommands.new({
      service_id: service_id,
      service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      deployment_name: deployment_name,
      request_base_url: request_base_url
    }) 
  }

  before do
    expect(class_double("UUID").as_stubbed_const).to receive(:new).and_return(uuid)
    expect(class_double("ServiceInstance").as_stubbed_const).to receive(:find_by_id).
      with(service_instance_id).
      and_return(service_instance)
    expect(service_instance).to receive(:service_plan_id).and_return(service_plan_id)

    expect(class_double("ServiceBinding").as_stubbed_const).to receive(:find_by_instance_id_and_binding_id).
      with(service_instance_id, service_binding_id).
      and_return(service_binding)
    expect(service_binding).to receive(:credentials).and_return(credentials)
    expect(service_binding).to receive(:save)
    expect(credentials).to receive(:[]=).with('binding_commands', expected_binding_commands)
  end

  it {
    expect(uuid).to receive(:generate).and_return(vms_state_uuid)
    expect(uuid).to receive(:generate).and_return(scale_1_server_uuid)
    expect(uuid).to receive(:generate).and_return(scale_2_servers_uuid)
    expect(uuid).to receive(:generate).and_return(scale_3_servers_uuid)
    subject.perform

    expect($etcd.get("/registered_binding_commands/#{service_binding_id}").value).to eq([
      vms_state_uuid, scale_1_server_uuid, scale_2_servers_uuid, scale_3_servers_uuid
    ].to_json)
  }
end
