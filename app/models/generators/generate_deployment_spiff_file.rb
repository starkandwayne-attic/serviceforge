class Generators::GenerateDeploymentSpiffFile
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service, :deployment_name

  def generate
    base_stub.
      gsub("NAME", deployment_name).
      gsub("PLACEHOLDER-DIRECTOR-UUID", bosh_director_uuid)
  end

  private
  def base_stub
    File.read(bosh_release_templates.deployment_stub_path)
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