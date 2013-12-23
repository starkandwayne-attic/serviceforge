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

  describe "#deploy" do
    describe "returns [:running, task_id]" do
      before {
        deploy_manifest = "--- {}"
        subject.api.should_receive(:deploy).with(deploy_manifest).and_return([:running, 123])
        @status, @task_id = subject.deploy(deploy_manifest)
      }
      it { expect(@status).to eq(:running) }
      it { expect(@task_id).to eq(123) }
    end
  end

  describe "#delete" do
    before {
      deployment_name = "foobar"
      subject.api.should_receive(:delete_deployment).with(deployment_name, force: true).and_return([:running, 123])
      @status, @task_id = subject.delete(deployment_name)
    }
    it { expect(@status).to eq(:running) }
    it { expect(@task_id).to eq(123) }
  end
end
