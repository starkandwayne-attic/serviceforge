class V2::ServiceInstancesController < V2::BaseController
  # This is actually the create
  def update
    if true
      instance = ServiceInstance.new({
        id: params.fetch(:id),
        service_id: params.fetch(:service_id),
        plan_id: params.fetch(:plan_id)
      })
      instance.save

      render status: 201, json: instance
    else
      render status: 507, json: {'description' => 'Service plan capacity has been reached'}
    end

  end

  def destroy
    if instance = ServiceInstance.find_by_id(params.fetch(:id))
      instance.destroy
      status = 200
    else
      status = 410
    end

    render status: status, json: {}
  end
end
