class V2::ServiceBindingsController < V2::BaseController

  # Following params provided by Rails routing:
  # * id                  - service_binding_id
  # * service_instance_id - service_instance_id
  #
  # Following params provided by Cloud Controller:
  # * plan_id        - service_plan_id (should be same as on ServiceInstance)
  # * service_id     - service_id
  # * app_guid       - not used currently
  def update
    service_instance_id = params.fetch(:service_instance_id)
    service_binding_id = params.fetch(:id)
    service_instance = ServiceInstance.find_by_id(service_instance_id)
    service_binding = ServiceBinding.create(service_binding_id: service_binding_id, service_instance_id: service_instance_id)

    service_id = service_instance.service_id
    service = Service.find_by_id(service_id)

    # Constructs the service binding credentials
    # from the Service configuration:
    # * default credentials such as a port
    # * detected credentials such as a host address
    action = Actions::PrepareServiceBinding.new(
      service_id: service_instance.service_id,
      service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      deployment_name: service_instance.deployment_name)
    action.perform

    action = Actions::CreateBindingCommands.new({
      service_id: service_id,
      service_instance_id: service_instance_id,
      service_binding_id: service_binding_id,
      deployment_name: service_instance.deployment_name,
      request_base_url: request_base_url
    })
    action.perform

    # reload after saves
    service_binding = ServiceBinding.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id)
    render status: 201, json: service_binding
  end

  def destroy
    service_instance_id = params.fetch(:service_instance_id)
    service_binding_id = params.fetch(:id)

    # action = Actions::DestroyBindingCommands.new(
    # 
    # )

    service_binding = ServiceBinding.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id)
    if service_binding
      service_binding.destroy
      status = 204
    else
      status = 410
    end

    render status: status, json: {}
  end

  protected
  def request_base_url
    ENV['SERVAAS_BASE_URL'] || Settings.base_url || request.base_url
  end
end
