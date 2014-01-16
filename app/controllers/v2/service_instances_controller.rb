class V2::ServiceInstancesController < V2::BaseController
  # This is actually the create
  def update
    if true
      instance = ServiceInstance.create({
        service_instance_id: params.fetch(:id),
        service_id: params.fetch(:service_id),
        service_plan_id: params.fetch(:plan_id)
      })

      action = Actions::CreateServiceInstance.new({
        service_id: params.fetch(:service_id),
        service_plan_id: params.fetch(:plan_id),
        service_instance_id: params.fetch(:id)
      })
      action.save
      action.perform

      # Need to reload 'instance' as it was modified by CreateServiceInstance action
      instance = ServiceInstance.find_by_id(instance.service_instance_id)
      instance.deployment_name = action.deployment_name
      instance.save

      render status: 201, json: instance.to_cf_json
    else
      render status: 507, json: {'description' => 'Service plan capacity has been reached'}
    end

  end

  def destroy
    if instance = ServiceInstance.find_by_id(params.fetch(:id))
      action = Actions::DeleteServiceInstance.create({
        service_instance_id: instance.service_instance_id,
        service_id: instance.service_id,
        deployment_name: instance.deployment_name
      })
      action.perform

      if wait_til_ready?
        Actions::WaitForServiceInstanceDeletion.new(
          service_id: service_id,
          service_instance_id: service_instance_id
        ).perform
      end
      status = 200
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
