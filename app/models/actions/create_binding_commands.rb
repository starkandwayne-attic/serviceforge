class Actions::CreateBindingCommands
  include EtcdModel

  attr_accessor :service_id, :service_instance_id, :service_binding_id, :deployment_name
  attr_accessor :request_base_url

  def perform
    commands = {
      # '1-server'  => { 'method' => 'PUT', 'url' => "#{request_base_url}/binding_commands/#{generate_binding_command_uuid}" },
      # '3-servers' => { 'method' => 'PUT', 'url' => "#{request_base_url}/binding_commands/#{generate_binding_command_uuid}" },
    }

    auth_token = generate_binding_command_uuid
    label = 'vms-state'
    http_method = 'GET'

    command = RegisteredBindingCommand.create(service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      auth_token: auth_token,
      label: label,
      http_method: http_method,
      klass: 'BindingCommandActions::Bosh::DeploymentVmState',
      attributes: {deployment_name: deployment_name, service_id: service_id})

    commands.merge!(command_hash(label, http_method, auth_token))
    
    service_binding.credentials['binding_commands'] = {
      'commands' => commands
    }
    
    service_binding.save
  end

  private
  def generate_binding_command_uuid
    uuid.generate
  end

  def uuid
    @uuid ||= UUID.new
  end

  def command_url(auth_token)
    "#{request_base_url}/binding_commands/#{auth_token}"
  end

  def command_hash(label, http_method, auth_token)
    { label => { 'method' => http_method, 'url' => command_url(auth_token) } }
  end
end