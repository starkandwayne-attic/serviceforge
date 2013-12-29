module EtcdModel
  extend ActiveSupport::Concern

  include ServiceAccessor
  include ActiveModel::Model

  included do
    def self.create(attributes)
      object = new(attributes)
      object.save
      object
    end
  end
end