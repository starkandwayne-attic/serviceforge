class BindingAttribute
  include ActiveModel::Model
  include ServiceAccessor

  # common
  attr_accessor :service_id, :deployment_name, :deployment_manifest
end