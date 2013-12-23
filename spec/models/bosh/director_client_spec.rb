require 'spec_helper'

describe Bosh::DirectorClient do
  subject { Bosh::DirectorClient.build({
      'target' => 'https://192.168.50.4:25555',
      'username' => 'admin',
      'password' => 'admin',
      'release_templates' => {
        'base_path' => '/path/to/templates',
        'templates' => ['file1.yml', 'file2.yml']
      }
    })
  }
  describe "#api" do
    it { expect(subject.api).to be_instance_of(Bosh::Cli::Client::Director) }
  end

  describe "#release_templates builds Bosh::ReleaseTemplates" do
    it { expect(subject.release_templates).to be_instance_of(Bosh::ReleaseTemplates) }
  end

  describe "#director_uuid cached on connection" do
    it do
      subject.api.should_receive(:get_status).and_return({"name"=>"Bosh Lite Director", "uuid"=>"UUID"})
      expect(subject.director_uuid).to eq("UUID")
    end
  end
end
