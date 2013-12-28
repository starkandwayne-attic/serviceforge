require 'spec_helper'

describe Actions::CreateBindingCommands do
  let(:service)               { instance_double("Service") }
  let(:service_binding)       { instance_double("ServiceBinding") }
  let(:service_id)            { 'service-1' }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:deployment_name)       { 'deployment-name' }
  let(:credentials)           { instance_double("Hash") }
  let(:scale_1_server_uuid)   { 'scale_1_server_uuid' }
  let(:scale_3_servers_uuid)  { 'scale_3_servers_uuid' }
  let(:expected_binding_commands) {
    {
      'current_plan' => '5-servers',
      'commands' => {
        '1-server'  => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/#{scale_1_server_uuid}" },
        '3-servers' => { 'method' => 'PUT', 'url' => "http://broker-address/binding_commands/#{scale_3_servers_uuid}" },
      }
    }
  }

  subject { Actions::CreateBindingCommands.new({
      service_id: service_id,
      service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      deployment_name: deployment_name
    }) 
  }

  before do
    expect(class_double("ServiceBinding").as_stubbed_const).to receive(:find_by_instance_id_and_binding_id).
      with(service_instance_id, service_binding_id).
      and_return(service_binding)
    expect(service_binding).to receive(:credentials).and_return(credentials)
    expect(service_binding).to receive(:save)
    expect(credentials).to receive(:[]=).with('binding_commands', expected_binding_commands)
  end

  it {
    expect(subject).to receive(:generate_binding_command_uuid).and_return(scale_1_server_uuid)
    expect(subject).to receive(:generate_binding_command_uuid).and_return(scale_3_servers_uuid)
    subject.perform
  }
end
