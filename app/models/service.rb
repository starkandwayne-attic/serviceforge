class Service
  attr_reader :id, :name, :description, :tags, :metadata, :plans, :bosh
  cattr_accessor :all

  def self.find_by_id(id)
    all.find { |service| service.id == id }
  end

  def self.build(attrs)
    plan_attrs = attrs['plans'] || []
    plans      = plan_attrs.map { |attr| Plan.build(attr) }
    if bosh_attrs = attrs['bosh']
      bosh = BoshDirectorClient.build(bosh_attrs)
    end
    new(attrs.merge('plans' => plans, 'bosh' => bosh))
  end

  def initialize(attrs)
    @id          = attrs.fetch('id')
    @name        = attrs.fetch('name')
    @description = attrs.fetch('description')
    @tags        = attrs.fetch('tags', [])
    @metadata    = attrs.fetch('metadata', nil)
    @bosh        = attrs.fetch('bosh', nil)
    @plans       = attrs.fetch('plans', [])
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

end
