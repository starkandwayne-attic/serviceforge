class Actions::CreateBindingCommands
  include EtcdModel

  attr_accessor :service_id
  attr_accessor :service_instance_id, :service_binding_id, :deployment_name
  attr_accessor :request_base_url

  attr_reader :commands, :command_auth_tokens

  def perform
    @commands = {}
    @command_auth_tokens = []

    register_vms_state_command

    service.plans.each do |plan|
      register_change_plan(plan)
    end

    save_registered_binding_commands
    save_commands_to_service_binding
  end

  private
  def generate_binding_command_uuid
    uuid.generate
  end

  def uuid
    @uuid ||= UUID.new
  end

  def service_plan_id
    service_instance.service_plan_id
  end

  def current_plan
    service.find_plan_by_id(service_plan_id)
  end

  def command_url(auth_token)
    "#{request_base_url}/binding_commands/#{auth_token}"
  end

  def command_hash(label, http_method, auth_token)
    { label => { 'method' => http_method, 'url' => command_url(auth_token) } }
  end

  def register_vms_state_command
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
    command_auth_tokens << auth_token
  end

  def register_change_plan(plan)
    auth_token = generate_binding_command_uuid
    label = plan.name
    service_plan_id = plan.id
    http_method = 'PUT'

    command = RegisteredBindingCommand.create(service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      auth_token: auth_token,
      label: label,
      http_method: http_method,
      klass: 'BindingCommandActions::Bosh::ChangeServicePlan',
      attributes: {
        deployment_name: deployment_name, service_id: service_id, service_instance_id: service_instance_id, service_plan_id: service_plan_id
      })

    commands.merge!(command_hash(label, http_method, auth_token))
    command_auth_tokens << auth_token
  end

  # To allow the Binding Commands be discovered and deleted later,
  # store them all in /registered_binding_commands/:service_binding_id
  def save_registered_binding_commands
    $etcd.set("/registered_binding_commands/#{service_binding_id}", command_auth_tokens.to_json)
  end

  def save_commands_to_service_binding
    service_binding.credentials['binding_commands'] = {
      'current_plan' => current_plan.name,
      'commands' => commands
    }
    service_binding.save
  end
end