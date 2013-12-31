class Bosh::ReleaseTemplates
  include ActiveModel::Model

  attr_accessor :base_path, :templates, :stub

  def self.build(attrs)
    new(attrs)
  end

  # Returns full paths to the ordered list of template files
  def template_paths
    @template_paths ||= templates.map {|t| File.join(base_path, t) }
  end

  def stub_path
    @stub_path ||= File.join(base_path, stub)
  end
end