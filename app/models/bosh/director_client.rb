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

  # Calls out to BOSH director to deploy/re-deploy a deployment
  # Returns [status, bosh_task_id]
  def deploy(yaml_manifest)
    status, task_id = api.deploy(yaml_manifest)
    [status, task_id]
  end
end