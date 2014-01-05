require 'spec_helper'

describe Bosh::ServiceBoshRelease do
  subject { Bosh::ServiceBoshRelease.build({
      'releases' => {
        'name' => 'redis',
        'version' => 3
      },
      'release_templates' => {
        'base_path' => '/path/to/templates',
        'templates' => ['file1.yml', 'file2.yml']
      }
    })
  }

  describe "#release_templates builds Bosh::ReleaseTemplates" do
    it { expect(subject.release_templates).to be_instance_of(Bosh::ReleaseTemplates) }
  end

end
