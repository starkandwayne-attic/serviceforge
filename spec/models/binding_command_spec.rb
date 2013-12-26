require 'spec_helper'

class DummyBindingCommand
  include ActiveModel::Model
  attr_accessor :some_attribute
  def perform; end
end

describe BindingCommand do
  let(:service)               { instance_double('Service') }
  let(:service_instance)      { instance_double('ServiceInstance') }
  let(:service_binding)       { instance_double('ServiceBinding') }
  let(:service_id)            { 'service-1' }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:deployment_name)       { 'deployment-name' }
  let(:auth_token)            { 'auth-token' }

  describe "lifecycle" do
    it do
      command = BindingCommand.new({
        service_instance_id: service_instance_id,
        service_binding_id: service_binding_id,
        auth_token: auth_token,
        klass: 'DummyBindingCommand',
        attributes: { 'some_attribute' => 'somevalue' }
      })
      command.save

      data = JSON.parse($etcd.get("/binding_commands/#{auth_token}/model").value)
      expect(data).to eq({
        'service_instance_id' => service_instance_id,
        'service_binding_id' => service_binding_id,
        'auth_token' => auth_token,
        'klass' => 'DummyBindingCommand',
        'attributes' => { 'some_attribute' => 'somevalue' }
      })

      command.perform

      command.destroy

      ##
      ## Test that etcd entries no longer exist
      ##
      expect{ $etcd.get("/binding_commands/#{auth_token}/model") }.to raise_error(Net::HTTPServerException)
    end
  end
end
