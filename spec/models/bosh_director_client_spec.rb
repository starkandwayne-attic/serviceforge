require 'spec_helper'

describe BoshDirectorClient do
  subject { BoshDirectorClient.build({
      'target' => 'https://192.168.50.4:25555',
      'username' => 'admin',
      'password' => 'admin'
    })
  }
  describe "#api" do
    it { expect(subject.api).to be_instance_of(Bosh::Cli::Client::Director) }
  end
end
