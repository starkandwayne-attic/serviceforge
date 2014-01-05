# 
class Bosh::ServiceBoshRelease
  include ActiveModel::Model

  attr_accessor :releases
  attr_accessor :release_templates

  def self.build(attrs)
    if release_templates_attrs = attrs.delete('release_templates')
      release_templates = Bosh::ReleaseTemplates.build(release_templates_attrs)
    end
    new(attrs.merge('release_templates' => release_templates))
  end

end