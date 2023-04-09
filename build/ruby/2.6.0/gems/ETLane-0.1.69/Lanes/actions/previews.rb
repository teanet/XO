require 'credentials_manager/account_manager'
require 'fastlane_core/itunes_transporter'
require 'rexml/document'
        # a = CredentialsManager::AccountManager.new(user: user, prefix: "deliver.appspecific", note: "application-specific")
        # @password = a.password(ask_if_missing: true) # to ask the user for the missing value

module Fastlane
  module Actions
    class PreviewsAction < Action
      def self.run(params)
        user = params[:username]
        product_bundle_identifier = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
        spaceship = Spaceship::Tunes.login(user)
        spaceship.team_id = CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id)
        app = Spaceship::Tunes::Application.find(product_bundle_identifier)
        app_id = app.apple_id()
        transporter = FastlaneCore::ItunesTransporter.new(user)
        destination = "/tmp"
        itmsp_path = File.join(destination, "#{app_id}.itmsp")
        transporter.download(app_id, destination)
        patch_itmsp(itmsp_path)
        transporter.upload(app_id, destination)
      end

      def self.patch_itmsp(itmsp_path)
        metadata_path = File.join(itmsp_path, "metadata.xml")
        doc = REXML::Document.new(File.read(metadata_path))
        current_version = doc.root.elements["software/software_metadata/versions[1]/version"]

        software_metadata = doc.root.elements["software/software_metadata"]
        software_metadata.elements.delete("products")
        software_metadata.elements.delete("in_app_purchases")
        versions = doc.root.elements["software/software_metadata/versions"]

        old_version = versions.elements[2]
        if old_version
          puts "Romove old version"
          versions.elements.delete(old_version)
        end

        build_folder = File.join(Dir.pwd, "build")
        preview_path = File.join(build_folder, "previews")

        current_version.elements.each("locales/locale") do |element| 

          element.elements.delete("app_previews")
          element.elements.delete("software_screenshots")
          element.elements.delete("title")
          element.elements.delete("subtitle")
          element.elements.delete("description")
          element.elements.delete("version_whats_new")
          element.elements.delete("privacy_url")
          element.elements.delete("support_url")
          element.elements.delete("keywords")

          locale = element.attributes["name"]
          locale_path = File.join(preview_path, locale)
          # если нет папки с локалью, значит удаляем видео
          app_previews = REXML::Element.new('app_previews')
          if File.directory?(locale_path)
            locale_files = Dir.entries(locale_path).select {|f| not File.directory?(f) }

            timestamp = "00:00:08:00"
            for file in locale_files do
              if file == "timestamp.txt"
                timestamp = File.read(File.join(locale_path, file))
              end
            end
            for file in locale_files do
              video_path = File.join(locale_path, file)
              if File.extname(file).downcase == ".mp4"
                size = File.size(video_path)
                if size > 500000
                  app_preview = generate_app_preview(itmsp_path, locale, video_path, timestamp)
                  app_previews.elements.add(app_preview)
                else
                  puts "#{video_path} too small, #{size}b"
                end
              end
            end
          end
          element.elements.add(app_previews)
        end  
        formatter = REXML::Formatters::Pretty.new
        formatter.compact = true
        formatter.width = 9999
        File.open(metadata_path,"w"){|file| file.puts formatter.write(doc.root,"")}
      end

      def self.generate_app_preview(itmsp_path, locale, video_path, timestamp)
        file = last = File.basename(video_path)
        file_with_locale = "#{locale}_#{file}"
        itmsp_video_path = File.join(itmsp_path, file_with_locale)
        FileUtils.cp(video_path, itmsp_video_path)
        file_name = File.basename(file, File.extname(file))

        app_preview = REXML::Element.new('app_preview')
        app_preview.add_attribute(REXML::Attribute.new('display_target', file_name))
        app_preview.add_attribute(REXML::Attribute.new('position', '1'))

        data_file = REXML::Element.new('data_file')
        data_file.add_attribute(REXML::Attribute.new('role', 'source'))

        size_node = REXML::Element.new('size')
        size = File.size(video_path)
        size_node.add_text("#{size}")
        data_file.elements.add(size_node)

        file_name_node = REXML::Element.new('file_name')
        file_name_node.add_text(file_with_locale)
        data_file.elements.add(file_name_node)

        checksum = REXML::Element.new('checksum')
        checksum.add_text(Digest::MD5.file(video_path).hexdigest)
        data_file.elements.add(checksum)

        app_preview.elements.add(data_file)

        preview_image_time = REXML::Element.new('preview_image_time')
        preview_image_time.add_attribute(REXML::Attribute.new('format', "30/1:1/nonDrop"))
        preview_image_time.add_text(timestamp)
        app_preview.elements.add(preview_image_time)

        app_preview
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Download Lokalise localization"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :username,
            env_name: "PREVIEW_USER_NAME",
            description: "User",
            verify_block: proc do |value|
               UI.user_error! "No API token for Lokalise given, pass using `api_token: 'token'`" unless (value and not value.empty?)
            end
          ),
        ]
      end

      def self.authors
        "teanet"
      end

      def self.is_supported?(platform)
        [:ios].include? platform 
      end
    end
  end
end
