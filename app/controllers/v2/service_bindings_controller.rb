class V2::ServiceBindingsController < V2::BaseController
  class ServiceInstanceNotReadyForBinding < StandardError; end

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
    service_instance = ServiceInstance.find_by_id(service_instance_id)

    service_id = service_instance.service_id

    unless service_instance.running?
      if wait_til_ready?
        Actions::WaitForServiceInstanceDeployment.new(
          service_id: service_id,
          service_instance_id: service_instance_id
        ).perform
      else
        Actions::UpdateServiceInstanceState.new(
          service_id: service_id,
          service_instance_id: service_instance_id
        ).perform
      end

      service_instance = ServiceInstance.find_by_id(service_instance_id)
      unless service_instance.running?
        raise ServiceInstanceNotReadyForBinding
      end
    end

    service_binding_id = params.fetch(:id)
    service_binding = ServiceBinding.create(service_binding_id: service_binding_id, service_instance_id: service_instance_id)

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

    # reload after saves
    service_binding = ServiceBinding.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id)
    render status: 201, json: service_binding
  rescue ServiceInstanceNotReadyForBinding
    render status: 403, json: { error: "Service Instance not ready for binding; state #{service_instance.state}" }.to_json
  end

  def destroy
    service_instance_id = params.fetch(:service_instance_id)
    service_binding_id = params.fetch(:id)

    action = Actions::DeleteBindingCommands.new(
      service_binding_id: service_binding_id
    )

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

  def wait_til_ready?
    params[:wait_til_ready]
  end
end
