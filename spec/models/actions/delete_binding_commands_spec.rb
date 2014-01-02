require 'spec_helper'

describe Actions::DeleteBindingCommands do
  let(:service_id)      { '1683fe81-b492-4e92-8282-0cdca7c316e1' } # redis-dedicated-bosh-lite
  let(:service_plan_id) { 'e23b4ad6-d33f-4764-803b-d507bb0b95d1' } # 2-servers

  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:request_base_url)      { 'http://broker-address' }

  let(:vms_state_uuid)        { 'vms_state_uuid' }
  let(:scale_1_server_uuid)   { 'scale_1_server_uuid' }

  subject { Actions::DeleteBindingCommands.new(
    service_binding_id: service_binding_id
  )}

  def cleanup_etcd
    $etcd.delete("/binding_commands", recursive: true)
    $etcd.delete("/registered_binding_commands", recursive: true)
  rescue Net::HTTPServerException
  end

  before do
    cleanup_etcd
    $etcd.set("/binding_commands/#{vms_state_uuid}", '{}')
    $etcd.set("/binding_commands/#{scale_1_server_uuid}", '{}')
    $etcd.set("/registered_binding_commands/#{service_binding_id}", [vms_state_uuid, scale_1_server_uuid].to_json)
  end

  it "deletes RegisteredBindingCommands" do
    subject.perform

    ##
    ## Test that BindingCommands have been removed
    ##
    expect($etcd.get("/binding_commands").value).to be_nil
    expect($etcd.get("/registered_binding_commands").value).to be_nil
  end
end
