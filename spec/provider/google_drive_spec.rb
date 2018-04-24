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
    it 'should run smoothly with all the options valid' do
      allow(provider[:provider]).to receive(:drive_root).and_return({})
      allow(::File).to receive(:directory?).and_return(true)
      expect{ provider[:provider].check_app }.not_to raise_error
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
    it 'should run smoothly when GOOGLE_DRIVE_SERVICE_ACCOUNT environment var is a valid service account' do
      provider[:provider].context.env['GOOGLE_DRIVE_SERVICE_ACCOUNT'] = 'VALID_KEY'
      allow(::GoogleDrive::Session).to receive(:from_service_account_key).and_return({})
      expect{ provider[:provider].check_auth }.not_to raise_error
    end
  end
end

# business logic test
describe DPL::Provider::GoogleDrive do
  subject(:provider) do
    described_class.new(DummyContext.new,
      shared: "./shared",
      project: "./project",
      strategy: "history"
    )
  end
  subject(:remove_provider) do
    described_class.new(DummyContext.new,
      shared: "./shared",
      project: "./project",
      strategy: "remove"
    )
  end
  describe '#drive_root' do
    it 'should run smoothly when the shared directory exists' do
      allow(provider).to receive(:session).and_return(double(file_by_name: 'file'))
      expect(provider.drive_root).to eql('file')
    end
    it 'should raise an error when the shared directory does not exists' do
      allow(provider).to receive(:session).and_return(double(file_by_name: nil))
      expect{provider.drive_root}.to raise_error(DPL::Error, 'Specified shared folder does not exist in your drive workspace')
    end
  end

  describe '#remove_strategy' do
    it 'should remove the old directory and creating the new one' do
      mocked_drive = double(
        file_by_name: 'build'
      )
      allow(mocked_drive).to receive(:remove).with('build'){|name| provider.context.shell "removing #{name}"}
      allow(mocked_drive).to receive(:create_subcollection).with('build'){|name| provider.context.shell "creating #{name}"}
      allow(provider).to receive(:drive_root).and_return(mocked_drive)
      expect(provider.context).to receive(:shell).with('removing build').and_return(true)
      expect(provider.context).to receive(:shell).with('creating build').and_return(true)
      provider.remove_strategy
    end
  end

  describe '#history_strategy' do
    it 'should create a directory with the correct name: current time' do
      allow_any_instance_of(::Time).to receive(:now).and_return(Time.at(0))
      allow(provider).to receive(:drive_root).and_return(double(create_subcollection: Time.at(0).strftime('%Y-%m-%d-%H-%M-%S')))
      expect(provider.history_strategy).to eq('1970-01-01-01-00-00')
    end
  end

  describe '#push_file' do
    it 'should create sub_directories and upload files' do
      working_dir = double
      allow(working_dir).to receive(:file_by_name).with('dir1').and_return(working_dir)
      allow(working_dir).to receive(:file_by_name).with('dir2').and_return(nil)
      allow(working_dir).to receive(:create_subcollection)do |arg|
        provider.context.shell "creating #{arg}"
        working_dir
      end
      allow(working_dir).to receive(:upload_from_file){|arg| provider.context.shell "uploading #{arg}"}
      allow(::File).to receive(:file?).and_return(true)
      expect(provider.context).to receive(:shell).with('creating dir2')
      expect(provider.context).to receive(:shell).with('uploading dir1/dir2/file')
      provider.push_file(working_dir, 'dir1/dir2/file')
    end
  end

  describe '#push_app' do
    it 'should create use the correct strategy' do
      allow_any_instance_of(described_class).to receive(:history_strategy){ provider.context.shell 'history strategy!'}
      allow_any_instance_of(described_class).to receive(:remove_strategy){ remove_provider.context.shell 'remove strategy!' }
      expect(provider.context).to receive(:shell).with('history strategy!').and_return(true)
      expect(remove_provider.context).to receive(:shell).with('remove strategy!').and_return(true)
      provider.push_app
      remove_provider.push_app
    end
  end
end
