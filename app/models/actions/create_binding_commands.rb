class Actions::CreateBindingCommands
  include ActiveModel::Model
  include Helpers::ServiceAccessor

  attr_accessor :service_id, :service_instance_id, :service_binding_id, :deployment_name

  def perform
    service_binding.credentials["binding_commands"] = {
      'current_plan' => current_plan_label,
      'commands' => {
        '1-server'  => { 'method' => 'PUT', 'url' => "#{request_host}/binding_commands/#{generate_binding_command_uuid}" },
        '3-servers' => { 'method' => 'PUT', 'url' => "#{request_host}/binding_commands/#{generate_binding_command_uuid}" },
      }
    }
    
    service_binding.save
  end

  private
  def generate_binding_command_uuid
    "xxx"
  end

  def request_host
    'http://broker-address'
  end

  def current_plan_label
    '5-servers'
  end
end