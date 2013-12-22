class V2::ServiceBindingsController < V2::BaseController
  def update
    instance = ServiceInstance.find_by_id(params.fetch(:service_instance_id))
    binding = ServiceBinding.new(id: params.fetch(:id), service_instance: instance)
    binding.save

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
