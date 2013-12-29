# Created when Broker received requests to delete a service. Performs the action
# of deleting a BOSH deployment.
#
# Example usage:
#   action = Actions::DeleteServiceInstance.new(
#     service_id: "b9698740-4810-4dc5-8da6-54581f5108c4",
#     service_instance_id: "foobar",
#     deployment_name: "etcd-dcb1c536-6c0b-11e3-9bba-8438354ccefa")
#   action.save
#   action.perform
class Actions::DeleteServiceInstance
  include EtcdModel

  # required for constructor
  attr_accessor :service_id, :service_instance_id, :deployment_name

  # set during usage
  attr_accessor :bosh_task_id

  def save
    $etcd.set("/actions/delete_service_instances/#{service_instance_id}", to_json)
  end

  def perform
    perform_bosh_delete_and_save_task_id(deployment_name)

    bosh_director_client.track_task(bosh_task_id)
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

end