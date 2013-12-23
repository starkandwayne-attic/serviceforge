class BoshDirectorClient
  include ActiveModel::Model

  attr_accessor :target, :username, :password
  attr_accessor :infrastructure

  attr_accessor :releases, :template

  # attributes looked up from director
  attr_accessor :dns_root, :cpi

  def self.build(attrs)
    new(attrs)
  end

  # Calls out to BOSH director to deploy/re-deploy a deployment
  def deploy_and_return_task_id(yaml_manifest)
    
  end
end