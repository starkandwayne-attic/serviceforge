require 'spec_helper'

describe Generators::GenerateDeploymentManifest do
  subject { Generators::GenerateDeploymentManifest.new }
  describe "#spiff_merge" do
    it "merges list of templates into output file" do
      subject.should_receive(:`).with("spiff file1.yml file2.yml > /path/output.yml")
      subject.spiff_merge(%w[file1.yml file2.yml], "/path/output.yml")
    end
  end
end
