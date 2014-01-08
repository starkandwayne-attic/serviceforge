require 'cli' # bosh_cli

# Wrapper around Bosh::Cli::Client::Director
# Exposes the required Director methods.
class Bosh::DirectorClient
  include ActiveModel::Model

  attr_accessor :target, :username, :password, :api_options
  attr_accessor :cpi_infrastructure
  attr_accessor :infrastructure_networks

  # attributes looked up from director
  attr_accessor :dns_root, :cpi

  def self.build(attrs)
    attrs['api_options'] ||= {no_track: true}
    if infrastructure_networks = attrs.delete('infrastructure_networks')
      infrastructure_networks.map! { |infra| Bosh::InfrastructureNetwork.build(infra) }
    end
    new(attrs.merge('infrastructure_networks' => infrastructure_networks))
  end

  def self.find_by_bosh_target(bosh_target)
    available_director_clients.find do |client|
      client.target == bosh_target
    end
  end

  def self.available_director_clients
    @available_director_clients ||= begin
      Settings.available_boshes.map do |bosh_config|
        build(bosh_config)
      end
    end
  end

  # FIXME should store these two in Etcd
  def available_infrastructure_networks
    return nil unless infrastructure_networks
    @available_infrastructure_networks ||= infrastructure_networks.clone
  end
  def allocated_infrastructure_networks
    return nil unless infrastructure_networks
    @allocated_infrastructure_networks ||= []
  end

  # FIXME Temporary method only required until above two lists stored in DB and can be cleaned out before tests
  def reset_infrastructure_network_for_testing
    return nil unless infrastructure_networks
    @available_infrastructure_networks = infrastructure_networks.clone
    @allocated_infrastructure_networks = []
  end

  def allocate_infrastructure_network
    return nil unless infrastructure_networks
    infra_network = available_infrastructure_networks.shift
    allocated_infrastructure_networks.push(infra_network)
    infra_network
  end

  def release_infrastructure_network(infrastructure_network)
    if network = allocated_infrastructure_networks.delete(infrastructure_network)
      available_infrastructure_networks.push(network)
    end
  end

  def api
    @api ||= Bosh::Cli::Client::Director.new(target, username, password, api_options)
  end

  def api_with_tracking
    @api_with_tracking ||= Bosh::Cli::Client::Director.new(target, username, password, api_options.merge(no_track: false))
  end

  def director_uuid
    @director_uuid ||= api.get_status["uuid"]
  end

  # Calls out to BOSH director to deploy/re-deploy a deployment
  # Returns [status, bosh_task_id]
  def deploy(yaml_manifest)
    status, task_id = api.deploy(yaml_manifest)
    [status, task_id]
  end

  def delete(deployment_name)
    status, task_id = api.delete_deployment(deployment_name, force: true)
    [status, task_id]
  end

  def list_deployments
    api.list_deployments
  end

  # returns true (the {"name" => deployment_name, ...} object) if deployment_name is a current deployment on BOSH
  def deployment_exists?(deployment_name)
    api.list_deployments.find { |deployment| deployment["name"] == deployment_name }
  end

  def list_vms(deployment_name)
    api.list_vms(deployment_name)
  end

  def fetch_vm_state(deployment_name, options={})
    options = options.dup

    url = "/deployments/#{deployment_name}/vms?format=full"

    status, task_id = api_with_tracking.request_and_track(:get, url, options)

    if status.to_sym != :done
      raise Bosh::Cli::DirectorError, "Failed to fetch VMs information from director (status: #{status}, task_id: #{task_id})"
    end

    output = api.get_task_result_log(task_id)

    result = output.to_s.split("\n").map do |vm_state|
      JSON.parse(vm_state)
    end
    [result, task_id]
  end

  # Returns:
  # * "done" if task completed successfully
  def task_state(task_id)
    api.get_task_state(task_id)
  end

  # returns BOSH status symbol (:done, :failed)
  def track_task(task_id)
    tracker = Bosh::Cli::TaskTracker.new(api, task_id)
    status  = tracker.track
  end

  def wait_for_tasks_to_complete(task_ids)
    until task_ids.empty?
      task_ids.each do |bosh_task_id|
        unless task_state(bosh_task_id) == "running"
          task_ids.delete(bosh_task_id)
        end
      end
    end
  end
end