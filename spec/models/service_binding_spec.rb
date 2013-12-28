require 'spec_helper'

describe ServiceBinding do
  let(:service_binding_id) { 'binding-id' }
  let(:service_instance_id) { 'instance-id' }

  before do
    ServiceBinding.create(service_instance_id: service_instance_id, service_binding_id: service_binding_id)
  end

  subject { ServiceBinding.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id) }

  describe '.find_by_instance_id_and_binding_id' do
    context "returns ServiceBinding" do
      it { expect(subject).to be_instance_of(ServiceBinding) }
      it { expect(subject.service_instance_id).to eq(service_instance_id) }
      it { expect(subject.service_binding_id).to eq(service_binding_id) }
    end

    it "returns nil if no entry found" do
      binding = ServiceBinding.find_by_instance_id_and_binding_id('xxx', 'yyy')
      expect(binding).to be_nil
    end
  end

  describe '#destroy' do
    it 'removes etcd entry' do
      subject.destroy

      expect{ $etcd.get("/service_instances/#{service_instance_id}/service_bindings/#{service_binding_id}/model") }.to raise_error(Net::HTTPServerException)
    end
  end

  describe '#to_json' do
    let(:json) { JSON.parse(binding.to_json) }
    it 'includes the credentials' do
      expect { json.has_key?("credentials") }.to be_true
    end
  end
end
