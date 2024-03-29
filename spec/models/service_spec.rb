require 'spec_helper'

describe Service do
  describe '.build' do
    before do
      allow(Plan).to receive(:build)
    end

    it 'sets fields correct' do
      service = Service.build(
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'stuff' => 'goes here' },
        'plans'       => []
      )
      expect(service.id).to eq('my-id')
      expect(service.name).to eq('my-name')
      expect(service.description).to eq('my description')
      expect(service.tags).to eq(['tagA', 'tagB'])
      expect(service.metadata).to eq({ 'stuff' => 'goes here' })
    end

    it 'is bindable' do
      service = Service.build(
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'stuff' => 'goes here' },
        'plans'       => []
      )

      expect(service).to be_bindable
    end

    it 'builds plans and sets the plans field' do
      plan_attrs = [double(:plan_attr1), double(:plan_attr2)]
      plan1      = double(:plan1)
      plan2      = double(:plan2)

      allow(Plan).to receive(:build).with(plan_attrs[0]).and_return(plan1)
      allow(Plan).to receive(:build).with(plan_attrs[1]).and_return(plan2)

      service = Service.build(
        'plans'       => plan_attrs,
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'stuff' => 'goes here' },
      )

      expect(service.plans).to eq([plan1, plan2])
    end

    context 'when the metadata attr is missing' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my description',
          'tags'        => ['tagA', 'tagB'],
          'plans'       => []
        )
      end

      it 'sets the field to nil' do
        expect(service.metadata).to be_nil
      end
    end

    context 'when the tags attr is missing' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my description',
          'metadata'    => { 'stuff' => 'goes here' },
          'plans'       => []
        )
      end

      it 'sets the field to an empty array' do
        expect(service.tags).to eq([])
      end
    end

    context 'when the default_credentials attr is missing' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my description',
          'tags'        => ['tagA', 'tagB'],
          'plans'       => []
        )
      end

      it 'sets the field to {}' do
        expect(service.default_credentials).to eq({})
      end
    end

    context 'when the detect_credentials attr is missing' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my description',
          'tags'        => ['tagA', 'tagB'],
          'plans'       => []
        )
      end

      it 'sets the field to {}' do
        expect(service.detect_credentials).to eq([])
      end
    end

  end

  describe '#to_hash' do
    it 'contains the right values' do
      service = Service.new(
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my-description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'meta' => 'data' },
        'plans'       => []
      )

      expect(service.to_hash.fetch('id')).to eq('my-id')
      expect(service.to_hash.fetch('name')).to eq('my-name')
      expect(service.to_hash.fetch('bindable')).to eq(true)
      expect(service.to_hash.fetch('description')).to eq('my-description')
      expect(service.to_hash.fetch('tags')).to eq(['tagA', 'tagB'])
      expect(service.to_hash.fetch('metadata')).to eq({ 'meta' => 'data' })
      expect(service.to_hash).to have_key('plans')
    end

    it 'includes the #to_hash for each plan' do
      plan_1         = double(:plan_1)
      plan_2         = double(:plan_2)
      plan_1_to_hash = double(:plan_1_to_hash)
      plan_2_to_hash = double(:plan_2_to_hash)

      expect(plan_1).to receive(:to_hash).and_return(plan_1_to_hash)
      expect(plan_2).to receive(:to_hash).and_return(plan_2_to_hash)

      service = Service.new(
        'plans'       => [plan_1, plan_2],
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my-description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'meta' => 'data' },
      )

      expect(service.to_hash.fetch('plans')).to eq([plan_1_to_hash, plan_2_to_hash])
    end

    context 'when there is no plans key' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my-description',
          'tags'        => ['tagA', 'tagB'],
          'metadata'    => { 'meta' => 'data' },
        )
      end

      it 'has an empty list of plans' do
        expect(service.to_hash.fetch('plans')).to eq([])
      end
    end

    # There might be a dangling "plans:" in the yaml, which assigns a nil value
    context 'when the plans key is nil' do
      let(:service) do
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my-description',
          'tags'        => ['tagA', 'tagB'],
          'metadata'    => { 'meta' => 'data' },
          'plans'       => nil,
        )
      end

      it 'has an empty list of plans' do
        expect(service.to_hash.fetch('plans')).to eq([])
      end
    end
  end

  describe "#find_plan_by_id" do

    before do
      plan_1_to_hash = double(:plan_1_to_hash)
      plan_2_to_hash = double(:plan_2_to_hash)
      @plan_1         = double(:plan_1, to_hash: plan_1_to_hash, id: "plan_1")
      @plan_2         = double(:plan_2, to_hash: plan_2_to_hash, id: "plan_2")
    end
    subject {
      Service.new(
        'plans'       => [@plan_1, @plan_2],
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my-description',
        'tags'        => ['tagA', 'tagB'],
        'metadata'    => { 'meta' => 'data' },
      )
    }

    it "finds plan" do
      plan = subject.find_plan_by_id("plan_1")
      expect(plan).to_not be_nil
      expect(plan.id).to eq("plan_1")
    end

    it "returns nil if plan does not exist" do
      expect(subject.find_plan_by_id("unknown")).to be_nil
    end

  end

  describe '#director_client references Bosh::DirectorClient (a wrapper of Bosh::Cli::Client::Director)' do
    context "bosh_target specified" do
      subject {
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my-desc',
          'bosh_target' => 'https://192.168.50.4:25555',
        )
      }

      it { expect(subject.bosh_target).to eq('https://192.168.50.4:25555') }

      context "Settings.available_boshes doesn't include target" do
        before do
          expect(Bosh::DirectorClient).to receive(:available_director_clients).and_return([
            instance_double('Bosh::DirectorClient', target: 'https://1.2.3.4:25555')
          ])
        end
        it { expect { subject.director_client }.to raise_error(Service::UnknownBoshTarget) }
      end

      context "Settings.available_boshes does include target" do
        let(:director) { instance_double('Bosh::DirectorClient', target: 'https://192.168.50.4:25555') }
        before do
          expect(Bosh::DirectorClient).to receive(:available_director_clients).and_return([director])
        end
        it { expect(subject.director_client).to eq(director) }
      end
    end

    context "no bosh_target specified" do
      subject {
        Service.build(
          'id'          => 'my-id',
          'name'        => 'my-name',
          'description' => 'my-desc',
        )
      }
      context "Settings.available_boshes includes targets" do
        let(:director) { instance_double('Bosh::DirectorClient', target: 'https://192.168.50.4:25555') }
        before do
          expect(Bosh::DirectorClient).to receive(:available_director_clients).and_return([director])
        end
        it "returns first target" do
          expect(subject.director_client).to eq(director)
        end
      end
    end
  end

  describe "bosh releases" do
    subject {
      Service.build(
        'id'          => 'my-id',
        'name'        => 'my-name',
        'description' => 'my-desc',
        'bosh_release' => {
          'releases' => {
            'name' => 'redis',
            'version' => 3
          },
          'release_templates' => {
            'base_path' => '/path/to',
            'templates' => ['file1.yml', 'file2.yml']
          }
        }
      )
    }
    it "#bosh_service_stub_paths" do
      expect(subject.bosh_service_stub_paths).to eq(["/path/to/file1.yml", "/path/to/file2.yml"])
    end

  end


end


