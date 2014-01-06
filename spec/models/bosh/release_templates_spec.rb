require 'spec_helper'

describe Bosh::ReleaseTemplates do
  describe "#build" do
    subject {
      Bosh::ReleaseTemplates.build({
        'base_path' => File.join(Rails.root, 'releases', 'etcd', 'templates'),
        'templates' => [
          'etcd-deployment.yml',
          'etcd-jobs.yml',
          'etcd-properties.yml',
          'etcd-infrastructure-warden.yml'
        ],
        'deployment_stub' => 'etcd-stub-spiff.yml',
        'infrastructure_stub' => 'etcd-stub-infrastructure-warden.yml'
      })
    }

    it { expect(File.basename(subject.base_path)).to eq('templates') }
    it { expect(subject.templates).to be_instance_of(Array) }

    it do
      first_template_path = subject.template_paths.first
      expect(File.exists?(first_template_path)).to be_true
    end

    it { expect(File.exists?(subject.deployment_stub_path)).to be_true }
    it { expect(File.exists?(subject.infrastructure_stub_path)).to be_true }
  end
end
