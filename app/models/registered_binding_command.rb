# Each RegisteredBindingCommand allows a single bound-application to invoke a command
# without any additional authentication or authorization. If they can provide
# a working auth_token then they are authorized to invoke to command, and
# also authenticated as a specific service instance & service binding.
#
# FIXME - there is some confusion between the parent record and the child records 
# and the associated Ruby models that could benefit from refactoring.
#
# When a ServiceBinding is created the following Etcd records are created
# * /binding_commands/TOKEN/model => via RegisteredBindingCommand via CreateBindingCommands
# * /registered_binding_commands/SERVICE_BINDING_ID => via CreateBindingCommands directly
#
# The second record allows the first group of records to be found and deleted when
# a ServiceBinding is deleted.
# It probably should be a model of its own with #save and #destroy methods.
class RegisteredBindingCommand
  include EtcdModel

  attr_accessor :label, :auth_token
  attr_accessor :service_instance_id, :service_binding_id

  # Which Binding class to invoke and the attributes to pass
  # to its constructor
  attr_accessor :klass, :attributes

  # How the RegisteredBindingCommand can be invoked:
  attr_accessor :http_method

  def self.find_by_auth_token(auth_token)
    if node = $etcd.get("/binding_commands/#{auth_token}/model")
      attributes = JSON.parse(node.value)
      new(attributes)
    end
  rescue Net::HTTPServerException
    # key not in etcd
  end

  def save
    $etcd.set("/binding_commands/#{auth_token}/model", to_json)
  end

  def destroy
    $etcd.delete("/binding_commands/#{auth_token}/model")
  end

  def perform
    binding_command_action.perform
  end

  def binding_command_action
    @binding_command_action ||= eval(klass).new(attributes)
  end
end