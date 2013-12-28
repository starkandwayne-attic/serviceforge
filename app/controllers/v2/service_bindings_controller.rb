class V2::ServiceBindingsController < V2::BaseController
  def update
    instance = ServiceInstance.find_by_id(params.fetch(:service_instance_id))
    binding_id = params.fetch(:id)
    binding = ServiceBinding.new(id: binding_id, service_instance: instance)
    binding.save

    service_id = instance.service_id
    service = Service.find_by_id(service_id)

    # Constructs the service binding credentials
    # from the Service configuration:
    # * default credentials such as a port
    # * detected credentials such as a host address
    action = Actions::PrepareServiceBinding.new(
      service_id: instance.service_id,
      service_binding_id: binding_id,
      deployment_name: instance.deployment_name)
    action.perform

    action = Actions::CreateBindingCommands.new({
      service_id: instance.service_id,
      service_instance_id: instance.id,
      service_binding_id: binding_id,
      deployment_name: instance.deployment_name
    })
    action.save # TODO necessary? can it be removed?
    action.perform

    render status: 201, json: binding
  end

  def destroy
    instance = ServiceInstance.find_by_id(params.fetch(:service_instance_id))
    if binding = ServiceBinding.find(instance, params.fetch(:id))
      binding.destroy
      status = 204
    else
      status = 410
    end

    render status: status, json: {}
  end
end
