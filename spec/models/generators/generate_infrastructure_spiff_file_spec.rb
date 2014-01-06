require 'spec_helper'

describe Generators::GenerateInfrastructureSpiffFile do
  let(:service_id)      { '1683fe81-b492-4e92-8282-0cdca7c316e1' } # redis-dedicated-bosh-lite
  let(:service)         { Service.find_by_id(service_id) }
  let(:template_file) { File.join(Rails.root, '/infrastructure_pools/warden/10.244.2.0.yml') }
  let(:infrastructure_network) { Bosh::InfrastructureNetwork.build({
      'ip_range_start' => '10.244.2.0',
      'template' => template_file
    })
  }

  it "creates Infrastructure spiff file for redis" do
    generator = Generators::GenerateInfrastructureSpiffFile.new(service: service, infrastructure_network: infrastructure_network)

    stub = generator.generate
    expect(stub).to eq(<<-YAML)
meta:
  environment: redis-warden

  stemcell:
    name: bosh-stemcell
    version: 993

update:
  canaries: 1
  max_in_flight: 50
  canary_watch_time: 1000-30000
  update_watch_time: 1000-30000

jobs:
  - name: redis_leader_z1
    instances: 1
    networks:
      - name: redis1
        static_ips: (( static_ips(0) ))
  - name: redis_z1
    instances: 2
    networks:
      - name: redis1
        static_ips: ~
    properties:
      redis:
        master: (( jobs.redis_leader_z1.networks.redis1.static_ips.[0] ))

compilation:
  cloud_properties:
    name: random

resource_pools:
  - name: small_z1
    cloud_properties:
      name: random

networks:
- name: redis1
  # Assume that no service plan for any service requires more than
  # 5 VMs, including 1 static and 4 dynamic.
  # Plus 5 (double the size) unused IPs, due to BOSH bug/quirk.
  subnets:
  - cloud_properties:
      name: random
    range: 10.244.2.0/30
    reserved:
    - 10.244.2.1
    static:
    - 10.244.2.2

  - cloud_properties:
      name: random
    range: 10.244.2.4/30
    reserved:
    - 10.244.2.5
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.8/30
    reserved:
    - 10.244.2.9
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.12/30
    reserved:
    - 10.244.2.13
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.16/30
    reserved:
    - 10.244.2.17
    static: []

  # Bonus double-sized network required due to BOSH oddity
  - cloud_properties:
      name: random
    range: 10.244.2.20/30
    reserved:
    - 10.244.2.21
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.24/30
    reserved:
    - 10.244.2.25
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.28/30
    reserved:
    - 10.244.2.29
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.32/30
    reserved:
    - 10.244.2.33
    static: []
  - cloud_properties:
      name: random
    range: 10.244.2.36/30
    reserved:
    - 10.244.2.37
    static: []
    YAML
  end
end
