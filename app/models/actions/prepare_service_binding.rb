# Constructs the service binding credentials
# from the Service configuration:
# * default credentials such as a port
# * detected credentials such as a host address
class Actions::PrepareServiceBinding
  include ActiveModel::Model
  include Helpers::ServiceAccessor

  # required for constructor
  attr_accessor :service_id, :service_binding_id, :deployment_name

  # resulting credentials value
  attr_accessor :credentials

  def perform
    start_with_default_credentials
    detect_binding_attributes
  end

  private
  def start_with_default_credentials
    self.credentials = service.default_credentials.clone
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

      credentials[binding_key] = binding_value
    end
  end
end