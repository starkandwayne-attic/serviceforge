class Actions::CreateBindingCommands
  include ActiveModel::Model

  attr_accessor :service_id, :service_instance_id, :service_binding_id, :deployment_name

  def perform
    # should update & save the service_binding with credentials
  end
end