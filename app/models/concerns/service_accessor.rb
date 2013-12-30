module ServiceAccessor
  extend ActiveSupport::Concern

  included do
    def service
      @service ||= Service.find_by_id(service_id)
    end

    def service_binding
      @service_binding ||= ServiceBinding.find_by_instance_id_and_binding_id(service_instance_id, service_binding_id)
    end

    def bosh_director_client
      service.bosh
    end
  end
end