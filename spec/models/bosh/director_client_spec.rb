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

  describe "#deploy(manifest)" do
    before {
      deploy_manifest = "--- {}"
      subject.api.should_receive(:deploy).with(deploy_manifest).and_return([:running, 123])
      @status, @task_id = subject.deploy(deploy_manifest)
    }
    it { expect(@status).to eq(:running) }
    it { expect(@task_id).to eq(123) }
  end

  describe "#delete(deployment_name)" do
    before {
      deployment_name = "foobar"
      subject.api.should_receive(:delete_deployment).with(deployment_name, force: true).and_return([:running, 123])
      @status, @task_id = subject.delete(deployment_name)
    }
    it { expect(@status).to eq(:running) }
    it { expect(@task_id).to eq(123) }
  end

  describe "#list_deployments" do
    it {
      subject.api.should_receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.list_deployments
      expect(result).to eq([{"name"=>"cf-warden"}])
    }
  end

  describe "#deployment_exists?(deployment_name)" do
    it "returns deployment object if api.list_deployments includes name" do
      subject.api.should_receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.deployment_exists?("cf-warden")
      expect(result).to be_instance_of(Hash)
      expect(result["name"]).to eq("cf-warden")
    end

    it "returns false if api.list_deployments does not include name" do
      subject.api.should_receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.deployment_exists?("deployment-xxx")
      expect(result).to be_false
    end
  end

  describe "#list_vms" do
    let(:vms) { [{"job"=>"etcd_leader_z1", "index"=>0}, {"job"=>"etcd_z1", "index"=>0}, {"job"=>"etcd_z1", "index"=>1}] }
    it {
      subject.api.should_receive(:list_vms).with("name").and_return(vms)
      result = subject.list_vms("name")
      expect(result).to eq(vms)
    }
  end

  describe "#track_task(task_id)" do
    let(:director) { instance_double('Bosh::Cli::Client::Director') }
    let(:task_id) { 123 }
    let(:task_tracker) { instance_double('Bosh::Cli::TaskTracker') }
    it "tracks a task until completed" do
      subject.should_receive(:api).and_return(director)
      tracker_klass = class_double('Bosh::Cli::TaskTracker').as_stubbed_const
      tracker_klass.should_receive(:new).with(director, task_id).and_return(task_tracker)
      task_tracker.should_receive(:track)
      subject.track_task(123)
    end
  end

  describe "#wait_for_tasks_to_complete(task_ids)" do
    it "waits for each task to stop running then returns" do
      subject.api.should_receive(:get_task_state).with(1).and_return("done")
      subject.api.should_receive(:get_task_state).with(2).and_return("running")
      subject.api.should_receive(:get_task_state).with(2).and_return("done")
      subject.wait_for_tasks_to_complete([1,2])
    end
  end
end
