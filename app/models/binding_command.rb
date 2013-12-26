# Each BindingCommand allows a single bound-application to invoke a command
# without any additional authentication or authorization. If they can provide
# a working auth_token then they are authorized to invoke to command, and
# also authenticated as a specific service instance & service binding.
class BindingCommand
  include ActiveModel::Model

  attr_accessor :auth_token
  attr_accessor :service_instance_id, :service_binding_id

  def save
    $etcd.set("/binding_commands/#{auth_token}/model", to_json)
  end

  def destroy
    $etcd.delete("/binding_commands/#{auth_token}/model")
  end
end