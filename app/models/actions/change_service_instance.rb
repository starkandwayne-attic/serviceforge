# Like CreateServiceInstance, but for an existing BOSH deployment
class Actions::ChangeServiceInstance
  include EtcdModel

  # required for constructor
  attr_accessor :service_id, :service_plan_id, :service_instance_id, :deployment_name

  # set during usage
  attr_accessor :bosh_task_id

  def save
    $etcd.set("/actions/change_service_instances/#{service_instance_id}", to_json)
  end

end