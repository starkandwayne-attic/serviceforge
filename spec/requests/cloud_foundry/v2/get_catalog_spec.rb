require 'spec_helper'

describe 'GET /v2/catalog' do
  it 'returns the catalog of services' do
    get '/v2/catalog'

    expect(response.status).to eq(200)
    catalog = JSON.parse(response.body)

    services = catalog.fetch('services')
    expect(services).to have(1).service

    service = services.first
    expect(service.fetch('name')).to eq('etcd-dedicated')
    expect(service.fetch('description')).to eq('etcd: A highly-available key value store for shared configuration and service discovery')
    expect(service.fetch('bindable')).to be_true
    expect(service.fetch('metadata')).to eq(
      {
        'provider' => { 'name' => 'Stark & Wayne LLC' },
        'listing' => {
          'imageUrl' => nil,
          'blurb' => 'A highly-available key value store for shared configuration and service discovery.',
          'long_description' => 'A highly-available key value store for shared configuration and service discovery. High-availablity clusters are available.'
        }
      }
    )

    plans = service.fetch('plans')
    expect(plans).to have(3).plan

    plan = plans.first
    expect(plan.fetch('name')).to eq('1-server')
    expect(plan.fetch('description')).to eq('Etcd running on a single dedicated server')
    expect(plan.fetch('metadata')).to eq(
      {
        'cost' => 100,
        'bullets' => [
          { 'content' => 'Etcd server' },
          { 'content' => 'Single small server' },
          { 'content' => 'Development-only, no high-availability' },
        ]
      }
    )
  end
end
