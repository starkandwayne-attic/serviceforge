require 'spec_helper'

describe Generators::GenerateDeploymentManifest do
  describe "#generate_manifest" do
    let (:service_stub_paths) { %w[file1.yml file2.yml] }
    subject { Generators::GenerateDeploymentManifest.new(service_stub_paths: service_stub_paths) }

    it "merges service plan & deployment stubs" do
      subject.service_plan_stub = "--- {}"
      subject.deployment_stub = "--- {}"
      expect(subject).to receive(:tempfile).with('service_plan_stub', "--- {}").and_return(double(path: "temp1"))
      expect(subject).to receive(:tempfile).with('deployment_stub', "--- {}").and_return(double(path: "temp2"))
      output_file = double(path: "output.yml", rewind: true, close: true, read: "OUTPUT")
      expect(subject).to receive(:tempfile).with('output').and_return(output_file)
      expect(subject).to receive(:spiff_merge).with(%w[file1.yml file2.yml temp1 temp2], "output.yml")
      manifest = subject.generate_manifest
      expect(manifest).to eq("OUTPUT")
    end
  end

  describe "#spiff_merge" do
    subject { Generators::GenerateDeploymentManifest.new }
    it "merges list of templates into output file" do
      expect(subject).to receive(:`).with("spiff merge file1.yml file2.yml > /path/output.yml")
      subject.spiff_merge(%w[file1.yml file2.yml], "/path/output.yml")
    end
  end
end
