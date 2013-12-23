class Actions::DeleteServiceInstance
  include ActiveModel::Model

  # required for constructor
  attr_accessor :service_id, :service_instance_id, :deployment_name

  # set during usage
  attr_accessor :bosh_task_id

  def save
    $etcd.set("/actions/delete_service_instances/#{service_instance_id}", to_json)
  end

  def perform
    perform_bosh_delete_and_save_task_id(deployment_name)
  end

  def to_json(*)
    {
      "service_id" => service_id,
      "service_instance_id" => service_instance_id,
      "deployment_name" => deployment_name,
      "bosh_task_id" => bosh_task_id
    }.to_json
  end

  private
  def perform_bosh_delete_and_save_task_id(deployment_name)
    status, self.bosh_task_id = bosh_director_client.delete(deployment_name)
    save
  end

  def bosh_director_client
    service.bosh
  end

  def service
    @service ||= Service.find_by_id(service_id)
  end

end