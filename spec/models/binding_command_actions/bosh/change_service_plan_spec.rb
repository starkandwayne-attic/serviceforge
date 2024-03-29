require 'spec_helper'

describe BindingCommandActions::Bosh::ChangeServicePlan do
  let(:service_id)          { 'service-id-1' }
  let(:service_plan_id)     { 'service-plan-id-1' }
  let(:service_instance_id) { 'service-instance-id-1' }
  let(:service_instance)    { instance_double('ServiceInstance') }
  let(:deployment_name)     { 'deployment-name' }
  let(:action)              { instance_double('Actions::ChangeServiceInstance') }

  subject { BindingCommandActions::Bosh::ChangeServicePlan.new({
    service_id: service_id,
    service_plan_id: service_plan_id,
    service_instance_id: service_instance_id,
    deployment_name: deployment_name
  })}

  it "changes deployment to a new service plan" do
    expect(class_double('ServiceInstance').as_stubbed_const).to receive(:find_by_id).with(service_instance_id).and_return(service_instance)
    expect(class_double('Actions::ChangeServiceInstance').as_stubbed_const).to receive(:create).
      with(service_id: service_id, service_plan_id: service_plan_id, service_instance_id: service_instance_id, deployment_name: deployment_name).
      and_return(action)
    expect(action).to receive(:perform)
    expect(action).to receive(:track_task).and_return("done")
    expect(service_instance).to receive(:deployment_successful!)
    subject.perform
  end
end
