class Bosh::InfrastructureNetwork
  include ActiveModel::Model

  attr_accessor :ip_range_start, :template

  def self.build(attrs)
    new(attrs)
  end

  def deployment_stub
    File.read(template)
  end

  def attributes
    {
      "ip_range_start" => ip_range_start,
      "template" => template
    }
  end

  # Comparison with Bosh::InfrastructureNetwork#ip_range_start
  def ==(object)
    if object.is_a?(self.class)
      object.ip_range_start == ip_range_start
    else
      false
    end
  end
end