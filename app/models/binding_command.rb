# Each BindingCommand allows a single bound-application to invoke a command
# without any additional authentication or authorization. If they can provide
# a working auth_token then they are authorized to invoke to command, and
# also authenticated as a specific service instance & service binding.
class BindingCommand
  include ActiveModel::Model

  attr_accessor :auth_token
  attr_accessor :service_instance_id, :service_binding_id

  # Which Binding class to invoke and the attributes to pass
  # to its constructor
  attr_accessor :klass, :attributes

  def save
    $etcd.set("/binding_commands/#{auth_token}/model", to_json)
  end

  def destroy
    $etcd.delete("/binding_commands/#{auth_token}/model")
  end

  def perform
    binding_command_object.perform
  end

  private
  def binding_command_object
    @binding_command_object ||= Object.const_get(klass).new(attributes)
  end
end