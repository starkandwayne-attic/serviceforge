class ServiceInstancesController < V2::BaseController
  def show
    render json: service_instance
  end

  def service_instance
    @service_instance ||= ServiceInstance.find_by_id(params[:id])
  end
end