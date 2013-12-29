# Constructs the service binding credentials
# from the Service configuration:
# * default credentials such as a port
# * detected credentials such as a host address
class Actions::PrepareServiceBinding
  include EtcdModel

  # required for constructor
  attr_accessor :service_id, :service_instance_id, :service_binding_id, :deployment_name

  def perform
    start_with_default_credentials
    detect_binding_attributes
    store_credentials_in_service_binding
  end

  private
  def start_with_default_credentials
    @credentials = service.default_credentials.clone
  end

  def detect_binding_attributes
    service.detect_credentials.each do |binding_cred|
      klass = eval(binding_cred['class'])
      klass_attributes = binding_cred['attributes']
      binding_key = binding_cred['name']
      binding_attr = klass.new({
        service_id: service_id,
        deployment_name: deployment_name,
        deployment_manifest: nil
      }.merge(klass_attributes))
      binding_value = binding_attr.value

      @credentials[binding_key] = binding_value
    end
  end

  def store_credentials_in_service_binding
    service_binding.credentials = @credentials
    service_binding.save
  end
end