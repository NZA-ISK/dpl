require 'google_drive'
module DPL
=begin
Initial step:
  1) create a Google Service Account
  2) share a Google Drive dir with the Service Account

ENV VARS
  GOOGLE_DRIVE_SERVICE_ACCOUNT --> encrypted Service Account credential in json format (encrypted via "travis encrypt" command line tool)

SCRIPT VARS
  shared --> shared dir
  project --> root dir to upload in Google Drive
  strategy [remove|history] --> the strategy you want to use to upload the directory
    remove --> always mantain one directory and every time remove the old one
    history --> create a new directory with a uniq timestamp every time

METHODS
Collection.create_subcollection // crea cartella
upload_from_file // upload file
collection_by_title // trova la cartella dal nome
collection_by_title("dir").upload_from_file("file") rescue create_subcollection("dir").upload_from_file("file")

=end
  class Provider
    class GoogleDrive < Provider
      def session
        @session
      end

      def check_auth
        raise Error, "Please add GOOGLE_DRIVE_SERVICE_ACCOUNT in Travis settings" if context.env['GOOGLE_DRIVE_SERVICE_ACCOUNT'].nil?
        begin
          file_name = "#{Time.now.to_i}.json"
          File.open(file_name, 'w') do |f|
            f.write(context.env['GOOGLE_DRIVE_SERVICE_ACCOUNT'])
          end
          @session = ::GoogleDrive::Session.from_service_account_key(file_name)
        rescue
          raise Error, 'Service account not valid'
        end
      end

      def project
        File.expand_path( (context.env['TRAVIS_BUILD_DIR'] || '.' ) + "/" + (options[:project] || '') )
      end

      def drive_root
        session.file_by_name(shared) || (raise Error, "Shared folder specified does not exist in your drive workspace")
      end

      def all_files
        # Returns a FLAT array with all the files (as path) in the target directory
        Dir["#{project}/**/*"]
      end

      def strategies
        %w(remove history)
      end

      def remove_strategy
        drive_root.remove(drive_root.file_by_name('build'))
        drive_root.create_subcollection('build')
      end

      def history_strategy
        drive_root.create_subcollection(Time.now.strftime('%Y-%m-%d-%H-%M-%S'))
      end

      def strategy
        options[:strategy]
      end

      def shared
        options[:shared]
      end

      def check_app
        raise Error, "Please set a valid 'project' folder path under 'deploy' in .travis.yml" unless File.directory?(project)
        raise Error, "Please set a 'shared' folder path under 'deploy' in .travis.yml" if drive_root.nil?
        raise Error, "Please use one of (#{strategies.join(' ')}) instead of #{strategy}" unless strategies.include?strategy
      end

      def push_file(working_dir, file)
        dirs = file.split('/')
        relative_dir = working_dir
        dirs[0...-1].each do |dir|
          clean_dir = dir.gsub(project, '')
          relative_dir = relative_dir.file_by_name(clean_dir) || relative_dir.create_subcollection(clean_dir)
        end
        relative_dir.upload_from_file(file) unless File.directory?file
      end

      def push_app
        working_dir = (options[:strategy].eql?'history') ? history_strategy : remove_strategy
        all_files.each { |file| push_file(working_dir, file) }
      end

      def needs_key?
        false
      end
    end
  end
end
