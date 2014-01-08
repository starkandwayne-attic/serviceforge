require 'spec_helper'

describe ServiceInstance do
  let(:service_instance_id) { 'instance-id' }
  let(:service_instance) { ServiceInstance.create(service_instance_id: service_instance_id, deployment_name: 'foo') }

  before do
    begin
      $etcd.delete("/service_instances", recursive: true)
    rescue Net::HTTPServerException
    end
  end

  describe "#create" do
    before { service_instance }  # trigger creation
    it 'stores in etcd' do
      data = JSON.parse($etcd.get("/service_instances/#{service_instance_id}/model").value)
      expect(data).to eq({
        'service_instance_id' => service_instance_id,
        'service_id' => nil,
        'service_plan_id' => nil,
        'deployment_name' => 'foo',
        'infrastructure_network' => nil
      })
    end
  end

  describe '#destroy' do
    it 'removes etcd entry' do
      service_instance.destroy

      expect{ $etcd.get("/service_instances/#{service_instance_id}/model") }.to raise_error(Net::HTTPServerException)
    end
  end

  describe '#to_json' do
    it 'is empty json' do
      hash = JSON.parse(service_instance.to_json)
      expect(hash).to eq({})
    end
  end

  describe '.find_by_id' do
    it "returns ServiceInstance if found in etcd" do
      service_instance.save
      service_instance = ServiceInstance.find_by_id(service_instance_id)
      expect(service_instance).to be_instance_of(ServiceInstance)
      expect(service_instance.service_instance_id).to eq(service_instance_id)
    end

    it "returns nil if not found in etcd" do
      service_instance = ServiceInstance.find_by_id('xxxx')
      expect(service_instance).to be_nil
    end
  end

  describe "infrastructure_network" do
    let(:template_file) { File.join(Rails.root, '/infrastructure_pools/warden/10.244.2.0.yml') }
    let(:infrastructure_network) { Bosh::InfrastructureNetwork.build({
        'ip_range_start' => '10.244.2.0',
        'template' => template_file
      })
    }
    it "initialize, saves and find_by_id" do
      subject.infrastructure_network = infrastructure_network
      subject.save
      reloaded = ServiceInstance.find_by_id(subject.service_instance_id)

      expect(reloaded.infrastructure_network.ip_range_start).to eq(infrastructure_network.ip_range_start)
    end
  end

end
