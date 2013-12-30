# Each BindingCommand allows a single bound-application to invoke a command
# without any additional authentication or authorization. If they can provide
# a working auth_token then they are authorized to invoke to command, and
# also authenticated as a specific service instance & service binding.
#
# TODO perhaps rename to RegisteredBindingCommand to decouple from
# the actual BindingCommands themselves
class BindingCommand
  include EtcdModel

  attr_accessor :label, :auth_token
  attr_accessor :service_instance_id, :service_binding_id

  # Which Binding class to invoke and the attributes to pass
  # to its constructor
  attr_accessor :klass, :attributes

  # How the BindingCommand can be invoked:
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
    binding_command.perform
  end

  def binding_command
    @binding_command ||= eval(klass).new(attributes)
  end
end