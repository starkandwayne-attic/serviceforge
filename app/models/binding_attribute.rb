class BindingAttribute
  include ActiveModel::Model
  include Helpers::ServiceAccessor

  # common
  attr_accessor :service_id, :deployment_name, :deployment_manifest
end