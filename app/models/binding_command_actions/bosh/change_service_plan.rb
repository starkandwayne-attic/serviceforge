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
    state = action.track_task
    case state.to_sym
      when :done
        service_instance.deployment_successful!
      when :running, :queued
        service_instance.deploying!
      else
        service_instance.failed_deployment!
    end
  end

  def to_json(*)
    {}.to_json
  end
end