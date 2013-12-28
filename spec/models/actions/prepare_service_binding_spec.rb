require 'spec_helper'

class DummyJobIpBindingAttribute < BindingAttribute
  attr_accessor :job_name
  def value
    "1.2.3.4"
  end
end

describe Actions::PrepareServiceBinding do
  let(:service)               { instance_double('Service') }
  let(:service_binding)       { instance_double('ServiceBinding') }
  let(:service_id)            { 'service-1' }
  let(:service_instance_id)   { 'service-instance-id-1' }
  let(:service_binding_id)    { 'service-binding-id-1' }
  let(:deployment_name)       { 'deployment-name' }
  let(:default_credentials)   { { 'port' => 4001 } }

  subject {
    Actions::PrepareServiceBinding.new(
      service_id: service_id,
      service_binding_id: service_binding_id,
      deployment_name: deployment_name)
  }

  before {
    expect(class_double('Service').as_stubbed_const).to receive(:find_by_id).with(service_id).and_return(service)
  }

  it "includes Service#default_credentials" do
    expect(service).to receive(:default_credentials).and_return(default_credentials)
    expect(service).to receive(:detect_credentials).and_return([])

    subject.perform

    expect(subject.credentials).to eq(default_credentials)
  end

  it "applies Service#detect_credentials" do
    expect(service).to receive(:default_credentials).and_return({})
    expect(service).to receive(:detect_credentials).and_return([
      {
        'name' => 'host',
        'class' => 'DummyJobIpBindingAttribute',
        'attributes' => {
          'job_name' => 'dummy-not-used'
        }
      }
    ])

    subject.perform

    expect(subject.credentials).to eq({
      'host' => '1.2.3.4'
    })
  end

  it "detect_credentials can override default_credentials" do
    expect(service).to receive(:default_credentials).and_return({"host" => "default", "port" => 1234})
    expect(service).to receive(:detect_credentials).and_return([
      {
        'name' => 'host',
        'class' => 'DummyJobIpBindingAttribute',
        'attributes' => {
          'job_name' => 'dummy-not-used-here-either'
        }
      }
    ])

    subject.perform

    expect(subject.credentials).to eq({
      'host' => '1.2.3.4',
      'port' => 1234
    })
  end
end
