require 'spec_helper'

describe Bosh::DirectorClient do
  let(:available_boshes) do
    [{"target"=>"https://192.168.50.4:25555",
      "username"=>"admin",
      "password"=>"admin",
      "dns_root"=>nil,
      "cpi_infrastructure"=>"warden",
      "infrastructure_networks"=>
       [{"ip_range_start"=>"10.244.2.0",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.0.yml")},
        {"ip_range_start"=>"10.244.2.40",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.40.yml")},
        {"ip_range_start"=>"10.244.2.80",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.80.yml")}]}]
  end

  subject { Bosh::DirectorClient.build({
      'target' => 'https://192.168.50.4:25555',
      'username' => 'admin',
      'password' => 'admin',
      "cpi_infrastructure"=>"warden",
      "infrastructure_networks"=>
       [{"ip_range_start"=>"10.244.2.0",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.0.yml")},
        {"ip_range_start"=>"10.244.2.40",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.40.yml")},
        {"ip_range_start"=>"10.244.2.80",
         "template"=>File.join(Rails.root, "/infrastructure_pools/warden/10.244.2.80.yml")}]
    })
  }

  describe ".available_director_clients from Settings" do
    before { expect(Settings).to receive(:available_boshes).at_most(:once).and_return(available_boshes) }
    subject { Bosh::DirectorClient.available_director_clients }
    it { expect(subject.size).to eq(1) }
    it { expect(subject.first).to be_instance_of(Bosh::DirectorClient) }
    it { expect(subject.first.username).to eq("admin") }
  end

  describe ".find_by_bosh_target from .available_director_clients" do
    before { expect(Settings).to receive(:available_boshes).at_most(:once).and_return(available_boshes) }
    let(:findable_target) { "https://192.168.50.4:25555" }
    let(:unknown_target) { "https://1.2.3.4:25555" }

    it "finds a DirectorClient" do
      client = Bosh::DirectorClient.find_by_bosh_target(findable_target)
      expect(client).to be_instance_of(Bosh::DirectorClient)
      expect(client.username).to eq("admin")
    end

    it "cannot find DirectorClient; returns nil" do
      client = Bosh::DirectorClient.find_by_bosh_target(unknown_target)
      expect(client).to be_nil
    end
  end

  describe ".infrastructure_networks" do
    it { expect(subject.infrastructure_networks.first).to be_instance_of(Bosh::InfrastructureNetwork) }
  end

  describe "#allocate_infrastructure_network to manage available InfrastructureNetworks" do
    it "allocates the 3 available infrastructures then returns nil" do
      expect(subject.allocate_infrastructure_network).to be_instance_of(Bosh::InfrastructureNetwork)
      expect(subject.allocate_infrastructure_network).to be_instance_of(Bosh::InfrastructureNetwork)
      expect(subject.allocate_infrastructure_network).to be_instance_of(Bosh::InfrastructureNetwork)
      expect(subject.allocate_infrastructure_network).to be_nil
      expect(subject.allocate_infrastructure_network).to be_nil
    end
  end

  describe "#api" do
    it { expect(subject.api).to be_instance_of(Bosh::Cli::Client::Director) }
  end

  describe "#director_uuid cached on connection" do
    it do
      expect(subject.api).to receive(:get_status).and_return({"name"=>"Bosh Lite Director", "uuid"=>"UUID"})
      expect(subject.director_uuid).to eq("UUID")
    end
  end

  describe "#deploy(manifest)" do
    before {
      deploy_manifest = "--- {}"
      expect(subject.api).to receive(:deploy).with(deploy_manifest).and_return([:running, 123])
      @status, @task_id = subject.deploy(deploy_manifest)
    }
    it { expect(@status).to eq(:running) }
    it { expect(@task_id).to eq(123) }
  end

  describe "#delete(deployment_name)" do
    before {
      deployment_name = "foobar"
      expect(subject.api).to receive(:delete_deployment).with(deployment_name, force: true).and_return([:running, 123])
      @status, @task_id = subject.delete(deployment_name)
    }
    it { expect(@status).to eq(:running) }
    it { expect(@task_id).to eq(123) }
  end

  describe "#list_deployments" do
    it {
      expect(subject.api).to receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.list_deployments
      expect(result).to eq([{"name"=>"cf-warden"}])
    }
  end

  describe "#deployment_exists?(deployment_name)" do
    it "returns deployment object if api.list_deployments includes name" do
      expect(subject.api).to receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.deployment_exists?("cf-warden")
      expect(result).to be_instance_of(Hash)
      expect(result["name"]).to eq("cf-warden")
    end

    it "returns false if api.list_deployments does not include name" do
      expect(subject.api).to receive(:list_deployments).and_return([{"name"=>"cf-warden"}])
      result = subject.deployment_exists?("deployment-xxx")
      expect(result).to be_false
    end
  end

  describe "#list_vms" do
    let(:vms) { [{"job"=>"etcd_leader_z1", "index"=>0}, {"job"=>"etcd_z1", "index"=>0}, {"job"=>"etcd_z1", "index"=>1}] }
    it {
      expect(subject.api).to receive(:list_vms).with("name").and_return(vms)
      result = subject.list_vms("name")
      expect(result).to eq(vms)
    }
  end

  describe "#fetch_vm_state(deployment_name)" do
    let(:vms_state_log) {
      <<-LOG
        {"job_name": "name", "index": 0, "ips": ["10.244.0.2"]}
        {"job_name": "name", "index": 1, "ips": ["10.244.0.6"]}
      LOG
    }
    let(:vms_state) {
      [{"job_name"=>"name", "index"=>0, "ips"=>['10.244.0.2']},
       {"job_name"=>"name", "index"=>1, "ips"=>['10.244.0.6']}]
    }
    let(:deployment_name) { "deployment-name"}
    let(:task_id) { 1234 }
    it {
      expect(subject.api_with_tracking).to receive(:request_and_track).with(:get, "/deployments/#{deployment_name}/vms?format=full", {}).and_return(["done", task_id])
      expect(subject.api).to receive(:get_task_result_log).with(task_id).and_return(vms_state_log)
      result, result_task_id = subject.fetch_vm_state(deployment_name)
      expect(result).to eq(vms_state)
      expect(result_task_id).to eq(task_id)
    }
  end

  describe "#track_task(task_id)" do
    let(:director) { instance_double('Bosh::Cli::Client::Director') }
    let(:task_id) { 123 }
    let(:task_tracker) { instance_double('Bosh::Cli::TaskTracker') }
    it "tracks a task until completed" do
      expect(subject).to receive(:api).and_return(director)
      tracker_klass = class_double('Bosh::Cli::TaskTracker').as_stubbed_const
      expect(tracker_klass).to receive(:new).with(director, task_id).and_return(task_tracker)
      expect(task_tracker).to receive(:track)
      subject.track_task(123)
    end
  end

  describe "#wait_for_tasks_to_complete(task_ids)" do
    it "waits for each task to stop running then returns" do
      expect(subject.api).to receive(:get_task_state).with(1).and_return("done")
      expect(subject.api).to receive(:get_task_state).with(2).and_return("running")
      expect(subject.api).to receive(:get_task_state).with(2).and_return("done")
      subject.wait_for_tasks_to_complete([1,2])
    end
  end
end
