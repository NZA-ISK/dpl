require 'time'
require 'google_drive'
require 'zip'

module DPL
=begin
Initial step:
  1) create a Google Service Account
  2) share a Google Drive dir with the Service Account

ENV VARS
  GDRIVE_SERVICE_ACCOUNT --> encrypted Service Account credential in json format (encrypted via "travis encrypt" command line tool)

SCRIPT VARS
  shared --> shared dir
  project --> root dir to upload in Google Drive

METHODS
Collection.create_subcollection // crea cartella
upload_from_file // upload file
collection_by_title // trova la cartella dal nome
collection_by_title("dir").upload_from_file("file") rescue create_subcollection("dir").upload_from_file("file")

=end
  class Provider
    class GoogleDrive < Provider
      def session
        file_name = "#{Time.now.to_i}.json"
        File.open(file_name, 'w') do |f|
          f.write(context.env['GDRIVE_SERVICE_ACCOUNT'])
        end
        GoogleDrive::Session.from_service_account_key(file_name)
      end

      def check_auth
        raise Error, "Please add GDRIVE_SERVICE_ACCOUNT in Travis settings" unless context.env['GDRIVE_SERVICE_ACCOUNT']
      end

      def project
        File.expand_path( (context.env['TRAVIS_BUILD_DIR'] || '.' ) + "/" + (options[:project] || '') )
      end

      def drive_root
        shared_dir = session.file_by_name(shared)
      end

      def all_files
        # Returns a FLAT array with all the files (as path) in the target directory
        Dir["#{project}/**/*"]
      end
      def all_directories
        # Returns a FLAT array with all the directories (as path) in the target directory
        Dir["#{project}/**/"]
      end

      def shared
        options[:shared]
      end

      def zipped
        options[:zip] || false
      end

      def check_app
        raise Error, "Please set a 'project' folder path under 'deploy' in .travis.yml" unless File.directory?(project)
        raise Error, "Please set a 'shared' folder path under 'deploy' in .travis.yml" if drive_root.nil?
      end

      def push_app
        # TODO: implementare algoritmo ricorsione
        # session.file_by_title("nome_cartella").upload_from_file("wewe")
        # TODO: deploy the code
      end

      def needs_key?
        false
      end
    end
  end
end
