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
      )
      without_strategy: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: nil
      ),
      random_strategy: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: "random"
      )
      provider: described_class.new(DummyContext.new,
        shared: "./shared",
        project: "./project",
        strategy: "history"
      )
    }
  end
  describe '#check_app' do
    it 'should raise an error without a valid project folder' do
      ::File.should_receive(:directory?).and_return(false)
      expect{ provider[:without_project].check_app }.to raise_error("Please set a valid 'project' folder path under 'deploy' in .travis.yml")
    end
    it 'should raise an error without a valid shared folder' do
      ::File.should_receive(:directory?).and_return(true)
      DPL::Provider::GoogleDrive.should_receive(:drive_root).and_return(nil)
      expect{ provider[:without_shared].check_app }.to raise_error("Please set a valid 'shared' folder path under 'deploy' in .travis.yml")
    end
    it 'should raise an error witouth a strategy' do
      DPL::Provider::GoogleDrive.should_receive(:drive_root).and_return({})
      ::File.should_receive(:directory?).and_return(true)
      expect{ provider[:without_strategy] }.to raise_error("Please use one of (remove history) instead of ")
    end
  end
  describe '#check_auth' do
    it 'should require GoogleDrive_SERVICE_ACCOUNT enviroments var' do
      provider.context.env['GoogleDrive_SERVICE_ACCOUNT'] = nil
      expect{ provider[:provider].check_auth }.to raise_error('Please add GoogleDrive_SERVICE_ACCOUNT in Travis settings')
    end
    it 'should raise an error if GoogleDrive_SERVICE_ACCOUNT is not a valid service account'
      ::GoogleDrive::Session.should_receive(:from_service_account_key).and_raise(Error)
      expect{ provider[:provider].check_auth }.to raise_error('Service account not valid')
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
