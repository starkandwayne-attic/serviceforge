require 'spec_helper'

describe Actions::DeleteServiceInstance do
  describe "delete a bosh-backed service instance" do
    let(:service)               { instance_double("Service") }
    let(:service_id)            { 'service-id-1' }
    let(:service_instance_id)   { 'service-instance-id-1' }
    let(:deployment_name_prefix) { 'etcd' }
    let(:deployment_uuid)       { "deployment-uuid" }
    let(:deployment_name)       { "#{deployment_name_prefix}-#{deployment_uuid}" }
    let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
    let(:bosh_delete_task_id)   { 124 }

    before do
      begin
        $etcd.delete("/actions", recursive: true)
      rescue Net::HTTPServerException
      end
    end

    it "deletes an existing service" do
      action = Actions::DeleteServiceInstance.create(service_id: service_id, service_instance_id: service_instance_id, deployment_name: deployment_name)

      ##
      ## Test the etcd entry
      ##
      data = JSON.parse($etcd.get("/actions/delete_service_instances/#{service_instance_id}").value)
      expect(data).to eq({
        'service_id' => service_id,
        'service_instance_id' => service_instance_id,
        'deployment_name' => deployment_name,
        'bosh_task_id' => nil
      })

      expect(action).to receive(:bosh_director_client).exactly(2).times.and_return(bosh_director_client)
      expect(bosh_director_client).to receive(:delete).with(deployment_name).and_return([:running, bosh_delete_task_id])
      expect(bosh_director_client).to receive(:track_task).with(bosh_delete_task_id).and_return("done")
      action.perform

      ##
      ## Test the etcd entry
      ##
      data = JSON.parse($etcd.get("/actions/delete_service_instances/#{service_instance_id}").value)
      expect(data).to eq({
        'service_id' => service_id,
        'service_instance_id' => service_instance_id,
        'deployment_name' => deployment_name,
        'bosh_task_id' => bosh_delete_task_id
      })
    end
  end
end
