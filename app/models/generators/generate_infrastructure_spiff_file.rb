class Generators::GenerateInfrastructureSpiffFile
  include ActiveModel::Model
  include ServiceAccessor

  attr_accessor :service, :infrastructure_network

  def generate
    infrastructure_network_stub
  end

  private

  def infrastructure_network_stub
    infrastructure_network.deployment_stub
  end

end