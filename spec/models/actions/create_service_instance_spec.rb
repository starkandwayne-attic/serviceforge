require 'spec_helper'

describe Actions::CreateServiceInstance do
  let(:service_instance_id) { 'service-instance-id-1' }

  before do
    begin
      $etcd.delete("/actions", recursive: true)
    rescue Net::HTTPServerException
    end
  end


  it "has lifecycle" do
    action = Actions::CreateServiceInstance.new(service_instance_id: service_instance_id)
    action.save

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/create_service_instances/#{service_instance_id}").value)
    expect(data).to eq({
      'service_instance_id' => service_instance_id
    })

    action.destroy
    expect{ $etcd.get("/actions/create_service_instances/#{service_instance_id}") }.to raise_error(Net::HTTPServerException)
  end
end
