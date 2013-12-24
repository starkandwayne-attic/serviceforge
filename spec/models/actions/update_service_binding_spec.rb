require 'spec_helper'

describe Actions::UpdateServiceBinding do
  let(:service)                { instance_double("Service") }
  let(:service_binding)        { instance_double("ServiceBinding") }
  let(:service_id)             { 'service-1' }
  let(:service_instance_id)    { 'service-instance-id-1' }
  let(:service_binding_id)     { 'service-binding-id-1' }
  let(:deployment_name_prefix) { 'test-etcd' }
  let(:deployment_name)        { "#{deployment_name_prefix}-#{service_instance_id}" }
  let(:bosh_director_client)  { instance_double("Bosh::DirectorClient") }
  let(:master_host_job_name)   { 'etcd_leader_z1' }
  let(:master_host_address)    { '10.244.2.6' }
  let(:vms_state) {
    [{"job_name"=>master_host_job_name, "index"=>0, "ips"=>[master_host_address]}]
  }
  let(:bosh_task_id)       { 123 }

  subject { Actions::UpdateServiceBinding.new({
    service_id: service_id,
    service_instance_id: service_instance_id,
    service_binding_id: service_binding_id,
    deployment_name: deployment_name,
    master_host_job_name: master_host_job_name
  }) }

  it "set host/hostname to primary server IP on all service instance bindings" do
    subject.save

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/update_service_binding/#{service_binding_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_binding_id' => service_binding_id,
      'deployment_name' => deployment_name,
      'master_host_job_name' => master_host_job_name,
      'master_host_job_index' => 0,
      'master_host_address' => nil,
      'bosh_task_id' => nil,
      'error' => nil
    })

    subject.should_receive(:bosh_director_client).and_return(bosh_director_client)
    bosh_director_client.should_receive(:fetch_vm_state).with(deployment_name).and_return([vms_state, bosh_task_id])

    subject.perform

    ##
    ## Test the etcd entry
    ##
    data = JSON.parse($etcd.get("/actions/update_service_binding/#{service_binding_id}").value)
    expect(data).to eq({
      'service_id' => service_id,
      'service_instance_id' => service_instance_id,
      'service_binding_id' => service_binding_id,
      'deployment_name' => deployment_name,
      'master_host_job_name' => master_host_job_name,
      'master_host_job_index' => 0,
      'master_host_address' => master_host_address,
      'bosh_task_id' => bosh_task_id,
      'error' => nil
    })

  end
end
