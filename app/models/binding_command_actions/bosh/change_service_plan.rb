class BindingCommandActions::Bosh::ChangeServicePlan
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service_id, :service_plan_id, :service_instance_id, :deployment_name

  def perform
    action = Actions::ChangeServiceInstance.create(
      service_id: service_id,
      service_plan_id: service_plan_id,
      service_instance_id: service_instance_id,
      deployment_name: deployment_name
    )
    action.perform
    action.track_task
  end

  def to_json(*)
    {}.to_json
  end
end