class Bosh::ReleaseTemplates
  include ActiveModel::Model

  attr_accessor :base_path, :templates
  attr_accessor :deployment_stub, :infrastructure_stub

  def self.build(attrs)
    new(attrs)
  end

  # Returns full paths to the ordered list of template files
  def template_paths
    @template_paths ||= templates.map {|t| File.join(base_path, t) }
  end

  def deployment_stub_path
    @stub_path ||= File.join(base_path, deployment_stub)
  end

  def infrastructure_stub_path
    @infrastructure_stub_path ||= File.join(base_path, infrastructure_stub)
  end
end