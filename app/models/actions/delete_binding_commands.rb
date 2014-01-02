class Actions::DeleteBindingCommands
  include EtcdModel

  attr_accessor :service_binding_id

  def perform
    registered_binding_commands = JSON.parse($etcd.get("/registered_binding_commands/#{service_binding_id}").value)
    registered_binding_commands.each do |binding_command_uuid|
      $etcd.delete("/binding_commands/#{binding_command_uuid}")
    end
    $etcd.delete("/registered_binding_commands/#{service_binding_id}")
  rescue Net::HTTPServerException
    # key not in etcd
  end
end