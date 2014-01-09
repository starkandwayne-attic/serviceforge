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

  class FailedDeleteServiceInstance < StandardError; end

  def save
    $etcd.set("/actions/delete_service_instances/#{service_instance_id}", to_json)
  end

  def perform
    begin
      status, self.bosh_task_id = bosh_director_client.delete(deployment_name)
      save
      service_instance.destroying!
      task_status = bosh_director_client.track_task(bosh_task_id)
      if task_status.to_sym == :done
        release_networking_and_mark_destroyed
      else
        raise FailedDeleteServiceInstance, "BOSH task #{bosh_task_id} completed with status #{task_status}"
      end
    rescue Bosh::Errors::ResourceNotFound
      release_networking_and_mark_destroyed
    end
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
  def release_networking_and_mark_destroyed
    bosh_director_client.release_infrastructure_network(service_instance.infrastructure_network)
    service_instance.destroyed!
  end

end