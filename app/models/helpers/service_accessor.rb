module Helpers::ServiceAccessor
  def service
    @service ||= Service.find_by_id(service_id)
  end

  def bosh_director_client
    service.bosh
  end
end