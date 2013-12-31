class BindingCommandActions::Bosh::ChangeServicePlan
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service_id, :deployment_name, :service_plan_id

  attr_reader :bosh_task_id

  def perform
  end

  def to_json(*)
    {}.to_json
  end
end