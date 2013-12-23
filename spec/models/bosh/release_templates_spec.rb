require 'spec_helper'

describe Bosh::ReleaseTemplates do
  describe "#build" do
    subject {
      Bosh::ReleaseTemplates.build({
        "base_path" => File.join(Rails.root, "templates"),
        "templates" => [
          "etcd-deployment.yml",
          "etcd-jobs.yml",
          "etcd-properties.yml",
          "etcd-infrastructure-warden.yml"
        ]
      })
    }

    it { expect(File.basename(subject.base_path)).to eq("templates") }
    it { expect(subject.templates).to be_instance_of(Array) }

    it do
      first_template_path = subject.template_paths.first
      expect(File.exists?(first_template_path)).to be_true
    end
  end
end
