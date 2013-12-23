require 'cli' # bosh_cli

class BoshDirectorClient
  include ActiveModel::Model

  attr_accessor :target, :username, :password, :api_options
  attr_accessor :infrastructure

  attr_accessor :releases, :template

  # attributes looked up from director
  attr_accessor :dns_root, :cpi

  def self.build(attrs)
    attrs['api_options'] ||= {}
    new(attrs)
  end

  def api
    @api ||= Bosh::Cli::Client::Director.new(target, username, password, api_options)
  end

  # Calls out to BOSH director to deploy/re-deploy a deployment
  def deploy_and_return_task_id(yaml_manifest)
    
  end
end