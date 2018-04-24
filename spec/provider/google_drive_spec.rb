require 'spec_helper'
require 'dpl/provider/google_drive'

# variables check test
describe DPL::Provider::GoogleDrive do
  subject :provider do
    {
      without_project: described_class.new(DummyContext.new,
        shared: './shared',
        project: nil,
        strategy: 'history'
      ),
      without_shared: described_class.new(DummyContext.new,
        shared: nil,
        project: './project',
        strategy: 'history'
      ),
      without_strategy: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: nil
      ),
      random_strategy: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: "random"
      ),
      provider: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: "history"
      )
    }
  end
  describe '#check_app' do
    it 'should raise an error without a valid project folder' do
      allow(::File).to receive(:directory?).and_return(false)
      expect{ provider[:without_project].check_app }.to raise_error(DPL::Error, "Please set a valid 'project' folder path under 'deploy' in .travis.yml")
    end
    it 'should raise an error without a valid shared folder' do
      allow(::File).to receive(:directory?).and_return(true)
      allow(provider[:without_shared]).to receive(:drive_root).and_return(nil)
      expect{ provider[:without_shared].check_app }.to raise_error(DPL::Error, "Please set a 'shared' folder path under 'deploy' in .travis.yml")
    end
    it 'should raise an error without a strategy' do
      allow(provider[:without_strategy]).to receive(:drive_root).and_return({})
      allow(::File).to receive(:directory?).and_return(true)
      expect{ provider[:without_strategy].check_app }.to raise_error(DPL::Error, "Please use one of (remove history) instead of ")
    end
    it 'should raise an error without a strategy included in the list' do
      allow(provider[:random_strategy]).to receive(:drive_root).and_return({})
      allow(::File).to receive(:directory?).and_return(true)
      expect{ provider[:random_strategy].check_app }.to raise_error(DPL::Error, "Please use one of (remove history) instead of random")
    end
  end
  describe '#check_auth' do
    it 'should require GOOGLE_DRIVE_SERVICE_ACCOUNT enviroments var' do
      provider[:provider].context.env['GOOGLE_DRIVE_SERVICE_ACCOUNT'] = nil
      expect{ provider[:provider].check_auth }.to raise_error('Please add GOOGLE_DRIVE_SERVICE_ACCOUNT in Travis settings')
    end
    it 'should raise an error if GoogleDrive_SERVICE_ACCOUNT is not a valid service account' do
      provider[:provider].context.env['GOOGLE_DRIVE_SERVICE_ACCOUNT'] = 'NOT_VALID_KEY'
      allow(::GoogleDrive::Session).to receive(:from_service_account_key).and_raise(DPL::Error)
      expect{ provider[:provider].check_auth }.to raise_error(DPL::Error, 'Service account not valid')
    end
  end
end

# business logic test
describe DPL::Provider::GoogleDrive do

  describe '#drive_root' do

  end


  describe '#project' do

  end

  describe '#strategies' do

  end
  describe '#remove_strategy' do

  end

  describe '#history_strategy' do

  end

  describe '#shared' do

  end

  describe '#push_file' do

  end

  describe '#push_app' do

  end

  describe '#strategy' do

  end
end
