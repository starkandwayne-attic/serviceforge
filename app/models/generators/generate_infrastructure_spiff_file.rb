class Generators::GenerateInfrastructureSpiffFile
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service, :infrastructure_network

  def generate
    base_stub.
      gsub("NETWORK", infrastructure_network_stub)
  end

  private
  def base_stub
    File.read(bosh_release_templates.infrastructure_stub_path)
  end

  def infrastructure_network_stub
    infrastructure_network.deployment_stub
  end

  def bosh_release
    service.bosh_release
  end

  def bosh_release_templates
    bosh_release.release_templates
  end

  def bosh_director_uuid
    bosh_director_client.director_uuid
  end
end