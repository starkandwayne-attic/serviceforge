class ServiceInstancesController < V2::BaseController
  def show
    if service_instance
      update_service_instance_state
      render json: service_instance
    else
      render json: {state: 'destroyed'}, status: 404
    end
  end

  protected
  def update_service_instance_state
    Actions::UpdateServiceInstanceState.new(
      service_id: service_id,
      service_instance_id: service_instance_id
    ).perform
  end

  # Always reloading ServiceInstance to ensure latest attributes
  def service_instance
    ServiceInstance.find_by_id(params[:id])
  end

  def service_instance_id
    service_instance.service_instance_id
  end

  def service_id
    service_instance.service_id
  end
end