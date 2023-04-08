# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'XO' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'SnapKit'
	pod 'VNBase', :git => 'https://github.com/teanet/VNBase.git', :branch => 'master'
	pod 'VNEssential', :git => 'https://github.com/teanet/VNBase.git', :branch => 'master'
	pod 'VNHandlers', :git => 'https://github.com/teanet/VNBase.git', :branch => 'master'

end

# Change default pods builds folder to avoid conflict with v4ios builds folder
post_install do |installer|

	treat_warnings_as_errors_default = ENV['TREAT_WARNINGS_AS_ERRORS'] ? ENV['TREAT_WARNINGS_AS_ERRORS'] : 'YES'

	installer.pods_project.build_configurations.each do |config|
		config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
	end
	installer.pods_project.targets.each do |target|
		if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
			target.build_configurations.each do |config|
				config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
			end
		end

		target.build_configurations.each do |config|
			config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
			config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'

			if config.name == 'Release'
				treat_warnings_as_errors = treat_warnings_as_errors_default
				config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 'fast'
				config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
				config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
			else
				config.build_settings['BITCODE_GENERATION_MODE'] = 'marker'
				config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
				treat_warnings_as_errors = 'NO'
			end

			if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
			end
			config.build_settings['SWIFT_VERSION'] = '5.0'
			if target.name.start_with?('VN', 'Pods')
				config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = treat_warnings_as_errors
				config.build_settings['SWIFT_TREAT_WARNINGS_AS_ERRORS'] = treat_warnings_as_errors
				config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'NO'
			else
				config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
				config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
			end

		end
	end

end
