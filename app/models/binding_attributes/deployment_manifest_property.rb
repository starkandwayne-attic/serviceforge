class BindingAttributes::DeploymentManifestProperty
  include ActiveModel::Model

  # common
  attr_accessor :service_id, :deployment_name, :deployment_manifest

  # specific to this BindingAttribute
  attr_accessor :key

  # Calculate the value for the BindingAttribute based on the deployment manifest
  def value
    deployment_manifest_yaml = YAML.parse(deployment_manifest)
    key_parts = key.strip.split(".")
    find_value(deployment_manifest_yaml.to_ruby, key_parts)
  end

  private
  def find_value(yaml, key_parts)
    return nil unless yaml && key_parts
    return yaml unless yaml.is_a?(Hash)

    first_key, *key_parts = key_parts
    return nil unless first_key
    value = yaml[first_key]
    find_value(value, key_parts)
  end
end