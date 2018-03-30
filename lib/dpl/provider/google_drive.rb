require 'time'
require 'zip'

module DPL
=begin
Step per funzionare:
  1) Creare un service account
  2) Condivedere una cartella del proprio drive con il service account


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
      def json_credentials
        session.upload_from_file("credentials.json", "bpippo.json", convert: false)
      end

      def check_auth
        raise Error, "Please add GDRIVE_SERVICE_ACCOUNT in Travis settings" unless context.env['GDRIVE_SERVICE_ACCOUNT']
      end

      def project
        File.expand_path( (context.env['TRAVIS_BUILD_DIR'] || '.' ) + "/" + (options[:project] || '') )
      end

      def check_app
        raise Error, "Please set a 'project' folder path under 'deploy' in .travis.yml" unless File.directory?(project)
      end

      def push_app
        # session.file_by_title("nome_cartella").upload_from_file("wewe")
        # TODO: deploy the code
      end

      def needs_key?
        false
      end
    end
end
