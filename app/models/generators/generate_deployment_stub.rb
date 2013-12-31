class Generators::GenerateDeploymentStub
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
    File.read(bosh_release_templates.stub_path)
  end

  def bosh_release_templates
    bosh_director_client.release_templates
  end

  def bosh_director_uuid
    bosh_director_client.director_uuid
  end
end