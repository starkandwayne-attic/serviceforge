class Service
  attr_reader :id, :name, :description, :tags, :metadata, :plans
  attr_reader :deployment_name_prefix

  attr_reader :bosh_target, :bosh_release
  attr_reader :default_credentials, :detect_credentials

  class UnknownBoshTarget < StandardError; end

  def self.all
    @all ||= (Settings['services'] || []).map {|attrs| Service.build(attrs)}
  end

  def self.find_by_id(id)
    all.find { |service| service.id == id }
  end

  def self.build(attrs)
    plan_attrs = attrs['plans'] || []
    plans      = plan_attrs.map { |attr| Plan.build(attr) }
    if bosh_release = attrs.delete("bosh_release")
      bosh_release = Bosh::ServiceBoshRelease.build(bosh_release)
    end
    new(attrs.merge('plans' => plans, 'bosh_release' => bosh_release))
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
    @bosh_target            = attrs.fetch('bosh_target', nil)
    @bosh_release           = attrs.fetch('bosh_release', nil)
  end

  def bindable?
    true
  end

  def director_client
    @director_client ||= find_bosh_director_client_or_default_to_first(@bosh_target)
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
    bosh_release.release_templates.template_paths
  end

  private
  def find_bosh_director_client_or_default_to_first(bosh_target)
    director_client = unless bosh_target
      Bosh::DirectorClient.available_director_clients.first
    else
      Bosh::DirectorClient.find_by_bosh_target(bosh_target)
    end
    unless director_client
      raise Service::UnknownBoshTarget, "Service #{name} bosh_target #{bosh_target.inspect} is unknown"
    end
    director_client
  end

end
