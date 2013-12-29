class Service
  attr_reader :id, :name, :description, :tags, :metadata, :plans
  attr_reader :deployment_name_prefix

  attr_reader :bosh, :release_templates
  attr_reader :default_credentials, :detect_credentials

  def self.all
    @all ||= (Settings['services'] || []).map {|attrs| Service.build(attrs)}
  end

  def self.find_by_id(id)
    all.find { |service| service.id == id }
  end

  def self.build(attrs)
    plan_attrs = attrs['plans'] || []
    plans      = plan_attrs.map { |attr| Plan.build(attr) }
    if bosh_attrs = attrs.delete('bosh')
      bosh = Bosh::DirectorClient.build(bosh_attrs)
    end
    new(attrs.merge('plans' => plans, 'bosh' => bosh))
  end

  def initialize(attrs)
    @id                     = attrs.fetch('id')
    @name                   = attrs.fetch('name')
    @deployment_name_prefix = attrs.fetch('deployment_name_prefix', @name)
    if Settings.extra_deployment_name_prefix
      @deployment_name_prefix = "#{Settings.extra_deployment_name_prefix}-#{@deployment_name_prefix}"
    end
    @description            = attrs.fetch('description')
    @tags                   = attrs.fetch('tags', [])
    @metadata               = attrs.fetch('metadata', nil)
    @plans                  = attrs.fetch('plans', [])

    @default_credentials    = attrs.fetch('default_credentials', {})
    @detect_credentials     = attrs.fetch('detect_credentials', [])
    @bosh                   = attrs.fetch('bosh', nil)
    @release_templates      = attrs.fetch('release_templates', nil)
  end

  def bindable?
    true
  end

  def to_hash
    {
      'id'          => self.id,
      'name'        => self.name,
      'description' => self.description,
      'tags'        => self.tags,
      'metadata'    => self.metadata,
      'plans'       => self.plans.map(&:to_hash),
      'bindable'    => self.bindable?
    }
  end

  def find_plan_by_id(plan_id)
    plans.find { |plan| plan.id == plan_id }
  end

  def bosh_service_stub_paths
    bosh.release_templates.template_paths
  end

end
