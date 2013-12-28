require 'spec_helper'

describe ServiceInstance do
  let(:id) { 'instance-id' }
  let(:instance) { ServiceInstance.new(id: id) }

  before do
    begin
      $etcd.delete("/service_instances", recursive: true)
    rescue Net::HTTPServerException
    end
  end

  describe '#save' do
    it 'stores in etcd' do
      instance.save

      data = JSON.parse($etcd.get("/service_instances/#{id}/model").value)
      expect(data).to eq({
        'id' => id,
        'service_id' => nil,
        'plan_id' => nil,
        'deployment_name' => nil
      })
    end
  end

  describe '#destroy' do
    it 'removes etcd entry' do
      instance.save
      instance.destroy

      expect{ $etcd.get("/service_instances/#{id}/model") }.to raise_error(Net::HTTPServerException)
    end
  end

  describe '#to_json' do
    it 'is empty json' do
      hash = JSON.parse(instance.to_json)
      expect(hash).to eq({})
    end
  end

  describe '.find_by_id' do
    it "returns ServiceInstance if found in etcd" do
      instance.save
      service_instance = ServiceInstance.find_by_id(id)
      expect(service_instance).to be_instance_of(ServiceInstance)
      expect(service_instance.id).to eq(id)
    end

    it "returns nil if not found in etcd" do
      service_instance = ServiceInstance.find_by_id(id)
      expect(service_instance).to be_nil
    end
  end

end
