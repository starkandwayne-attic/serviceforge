require 'spec_helper'

describe Actions::CreateBindingCommands do
  let(:service)               { instance_double("Service") }
  let(:service_binding)       { instance_double("ServiceBinding") }
  let(:service_id)            { 'service-1' }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:deployment_name)       { 'deployment-name' }

  subject { Actions::CreateBindingCommands.new({
      service_id: service_id,
      service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      deployment_name: deployment_name
    }) 
  }

  it "set host to primary server IP on all service instance bindings" do
    subject.save

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/create_binding_commands/#{service_binding_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_binding_id' => service_binding_id,
      'deployment_name' => deployment_name
    })

    subject.perform
  end
end
