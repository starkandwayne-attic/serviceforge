class BindingAttribute
  include ActiveModel::Model

  # common
  attr_accessor :service_id, :deployment_name, :deployment_manifest

  protected
  def service
    @service ||= Service.find_by_id(service_id)
  end

  def bosh_director_client
    service.bosh
  end

end