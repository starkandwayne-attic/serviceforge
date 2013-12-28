class V2::ServiceBindingsController < V2::BaseController
  def update
    service_instance_id = params.fetch(:service_instance_id)
    service_instance = ServiceInstance.find_by_id(service_instance_id)
    service_binding_id = params.fetch(:id)
    service_binding = ServiceBinding.create(service_binding_id: service_binding_id, service_instance_id: service_instance_id)

    service_id = service_instance.service_id
    service = Service.find_by_id(service_id)

    # Constructs the service binding credentials
    # from the Service configuration:
    # * default credentials such as a port
    # * detected credentials such as a host address
    action = Actions::PrepareServiceBinding.new(
      service_id: service_instance.service_id,
      service_binding_id: service_binding_id,
      deployment_name: service_instance.deployment_name)
    action.perform

    action = Actions::CreateBindingCommands.new({
      service_id: service_instance.service_id,
      service_instance_id: service_instance.id,
      service_binding_id: service_binding_id,
      deployment_name: service_instance.deployment_name
    })
    action.save # TODO necessary? can it be removed?
    action.perform

    render status: 201, json: service_binding
  end

  def destroy
    service_instance_id = params.fetch(:service_instance_id)
    service_instance = ServiceInstance.find_by_id(service_instance_id)
    if service_binding = ServiceBinding.find(service_instance, params.fetch(:id))
      service_binding.destroy
      status = 204
    else
      status = 410
    end

    render status: status, json: {}
  end
end
