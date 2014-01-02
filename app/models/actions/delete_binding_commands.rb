class Actions::DeleteBindingCommands
  include EtcdModel

  attr_accessor :service_binding_id

  def perform
    delete_binding_commands
    delete_list_of_registered_commands
  rescue Net::HTTPServerException
    # /registered_binding_commands/#{service_binding_id} key not in etcd
  end

  private
  def delete_binding_commands
    registered_binding_commands = JSON.parse($etcd.get("/registered_binding_commands/#{service_binding_id}").value)
    registered_binding_commands.each do |binding_command_uuid|
      begin
        $etcd.delete("/binding_commands/#{binding_command_uuid}")
      rescue Net::HTTPServerException
        # key not in etcd
      end
    end
  end

  def delete_list_of_registered_commands
    $etcd.delete("/registered_binding_commands/#{service_binding_id}")
  end
end