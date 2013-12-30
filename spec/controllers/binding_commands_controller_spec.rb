require 'spec_helper'

describe BindingCommandsController do
  let(:unique_binding_auth_token) { 'unique-binding-auth-token' }
  let(:command) { instance_double('BindingCommand') }
  let(:command_action) { instance_double('BindingCommands::Bosh::DeploymentVmState') }

  describe "invoke commands" do
    describe "to find and perform a registered command" do
      before do
        expect(BindingCommand).to receive(:find_by_auth_token).with(unique_binding_auth_token).and_return(command)
        expect(command).to receive(:perform)
        expect(command).to receive(:binding_command).and_return(command_action)
        expect(command_action).to receive(:to_json).and_return("{'some': 'json'}")
      end

      it {
        put :update, binding_auth_token: unique_binding_auth_token
        expect(response.status).to eq(200)
        expect(response.body).to eq("{'some': 'json'}")
      }
    end

    it "returns 401 unauthorized if using invalid/unknown auth_code" do
      put :update, binding_auth_token: 'xxxxx'
      expect(response.status).to eq(401)
    end
  end
end
