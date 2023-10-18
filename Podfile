platform :ios, '13.0'

use_frameworks!
inhibit_all_warnings!

target 'MobileWallet' do
  pod 'Tor', '408.4.1'
  pod 'lottie-ios'
  pod 'SwiftEntryKit', '2.0.0'
  pod 'ReachabilitySwift'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.1.0'
  pod 'SwiftKeychainWrapper', '3.4.0'
  pod 'Giphy', '2.1.22'
  pod 'IPtProxy', '1.10.1'
  pod 'OpenSSL-Universal'
  pod 'Zip', '2.1.2'
  pod 'SwiftyDropbox', '8.2.1'
  pod 'YatLib', '0.3.3'
  pod 'TariCommon', '0.2.0'
end

post_install do |installer|

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end

  installer.aggregate_targets.each do |target|
      target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
          xcconfig_path = config.base_configuration_reference.real_path
          IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end
end