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
  network_name: (( merge ))

networks:
- name: (( meta.network_name ))
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
