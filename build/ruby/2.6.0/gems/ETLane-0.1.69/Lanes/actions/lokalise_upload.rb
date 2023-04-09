require 'base64'

module Fastlane
  module Actions
    class LokaliseUploadAction < Action
      def self.run(params)
        
        self.snapshot(params)
        sources = params[:sources]
        languages = params[:languages]
        accepted_formats = [".strings", ".stringsdict"]
        for source in sources do
          Dir.chdir(source) do
            Dir.glob('*').select { |f| File.directory? f
              for lang in languages
                folder = "#{lang}.lproj"
                if f == folder
                  Dir.chdir(folder) do 
                    Dir.glob('*').select { |f| accepted_formats.include? File.extname(f)
                      upload_name = File.join(source, folder, f)
                      File.open(f, 'rb') do |img|
                        base64 = Base64.strict_encode64(img.read)
                        upload(lang, upload_name, base64, params)
                      end
                    }
                  end
                end
              end
              
            }
          end
        end


        # UI.error "Bad response 🉐\n#{response.body}" unless jsonResponse.kind_of? Hash
        # fileURL = jsonResponse["bundle_url"]
        # if fileURL.kind_of?(String)  then
        #   UI.message "Downloading localizations archive 📦"
        #   FileUtils.mkdir_p("lokalisetmp")
        #   uri = URI(fileURL)
        #   http = Net::HTTP.new(uri.host, uri.port)
        #   http.use_ssl = true
        #   zipRequest = Net::HTTP::Get.new(uri)
        #   response = http.request(zipRequest)
        #   if response.content_type == "application/zip" or response.content_type == "application/octet-stream" then
        #     FileUtils.mkdir_p("lokalisetmp")
        #     open("lokalisetmp/a.zip", "wb") { |file| 
        #       file.write(response.body)
        #     }
        #     unzip_file("lokalisetmp/a.zip", destination, clean_destination)
        #     FileUtils.remove_dir("lokalisetmp")
        #     UI.success "Localizations extracted to #{destination} 📗 📕 📘"
        #   else
        #     UI.error "Response did not include ZIP"
        #   end
        # elsif jsonResponse["response"]["status"] == "error"
        #   code = jsonResponse["response"]["code"]
        #   message = jsonResponse["response"]["message"]
        #   UI.error "Response error code #{code} (#{message}) 📟"
        # else
        #   UI.error "Bad response 🉐\n#{jsonResponse}"
        # end
      end

      def self.snapshot(params)
        require 'net/http'
        project_identifier = params[:project_identifier]
        uri = URI("https://api.lokalise.com/api2/projects/#{project_identifier}/snapshots")
        request_data = {
          title: params[:snapshot_version],
        }
        request = Net::HTTP::Post.new(uri)
        request.body = request_data.to_json
        request['X-Api-Token'] = params[:api_token]
        request['Content-Type'] = 'application/json'
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.request(request)
        jsonResponse = JSON.parse(response.body)
        puts jsonResponse
      end

      def self.upload(lang, name, data, params)
        require 'net/http'
        token = params[:api_token]
        project_identifier = params[:project_identifier]
        if lang == "es-419"
          lang = "es_419"
        end
        puts "Lang: #{lang} #{name}"
        request_data = {
          filename: name,
          data: data,
          lang_iso: lang,
          cleanup_mode: true,
        }
        uri = URI("https://api.lokalise.com/api2/projects/#{project_identifier}/files/upload")
        request = Net::HTTP::Post.new(uri)
        request.body = request_data.to_json
        request['X-Api-Token'] = token
        request['Content-Type'] = 'application/json'
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.request(request)
        jsonResponse = JSON.parse(response.body)
        puts jsonResponse

      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload Lokalise localization"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "LOKALISE_API_TOKEN",
                                       description: "API Token for Lokalise",
                                       verify_block: proc do |value|
                                          UI.user_error! "No API token for Lokalise given, pass using `api_token: 'token'`" unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :snapshot_version,
                                       env_name: "LOKALISE_SNAPSHOT_VERSION",
                                       description: "snapshot version for Lokalise",
                                       verify_block: proc do |value|
                                          UI.user_error! "No API token for Lokalise given, pass using `api_token: 'token'`" unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :project_identifier,
                                       env_name: "LOKALISE_PROJECT_ID",
                                       description: "Lokalise Project ID",
                                       verify_block: proc do |value|
                                          UI.user_error! "No Project Identifier for Lokalise given, pass using `project_identifier: 'identifier'`" unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :sources,
                                       description: "Localization sources",
                                       is_string: false,
                                       verify_block: proc do |value|
                                          UI.user_error! "Tags should be passed as array" unless value.kind_of? Array
                                       end),
            FastlaneCore::ConfigItem.new(key: :languages,
                                        description: "Include only the languages",
                                        optional: true,
                                        is_string: false,
                                        default_value: ["en"],
                                        verify_block: proc do |value|
                                          UI.user_error! "Tags should be passed as array" unless value.kind_of? Array
                                        end),

        ]
      end

      def self.authors
        "teanet"
      end

      def self.is_supported?(platform)
        [:ios, :mac].include? platform 
      end
    end
  end
end
