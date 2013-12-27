require 'spec_helper'

describe BindingAttributes::DeploymentManifestProperty do
  let(:deployment_manifest) {
    <<-YAML
properties:
  service:
    port: 4001
    secret: some-secret
    YAML
  }

  subject do
    BindingAttributes::DeploymentManifestProperty.new({
      deployment_manifest: deployment_manifest
    })
  end

  describe "extract property" do
    it "integer value" do
      subject.key = "properties.service.port"
      expect(subject.value).to eq(4001)
    end
    it "string value" do
      subject.key = "properties.service.secret"
      expect(subject.value).to eq("some-secret")
    end
    it "returns nil if key not found" do
      subject.key = "properties.not.found"
      expect(subject.value).to be_nil
    end
  end
end
