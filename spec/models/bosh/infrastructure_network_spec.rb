require 'spec_helper'

describe Bosh::InfrastructureNetwork do
  let(:template_file) { File.join(Rails.root, '/infrastructure_pools/warden/10.244.2.0.yml') }

  subject {
    Bosh::InfrastructureNetwork.build({
      'ip_range_start' => '10.244.2.0',
      'template' => template_file
    })
  }

  it { expect(subject.ip_range_start).to eq("10.244.2.0") }

  describe "#deployment_stub" do
    it {
      file_contents = File.read(template_file)
      expect(subject.deployment_stub).to eq(file_contents)
    }
  end
end
