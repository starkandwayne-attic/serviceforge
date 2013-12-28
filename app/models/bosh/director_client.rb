require 'cli' # bosh_cli

# Wrapper around Bosh::Cli::Client::Director
# Exposes the required Director methods.
class Bosh::DirectorClient
  include ActiveModel::Model

  attr_accessor :target, :username, :password, :api_options
  attr_accessor :infrastructure

  attr_accessor :releases, :release_templates

  # attributes looked up from director
  attr_accessor :dns_root, :cpi

  def self.build(attrs)
    attrs['api_options'] ||= {no_track: true}
    if release_templates_attrs = attrs.delete('release_templates')
      release_templates = Bosh::ReleaseTemplates.build(release_templates_attrs)
    end
    new(attrs.merge('release_templates' => release_templates))
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

  def task_state(task_id)
    api.get_task_state(task_id)
  end

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