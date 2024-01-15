platform :ios, '15.0'

use_frameworks!
inhibit_all_warnings!

target 'MobileWallet' do
  pod 'Tor', '408.10.1'
  pod 'lottie-ios'
  pod 'SwiftEntryKit', '2.0.0'
  pod 'ReachabilitySwift'
  pod 'Sentry', '8.14.2'
  pod 'SwiftKeychainWrapper', '3.4.0'
  pod 'Giphy', '2.1.22'
  pod 'IPtProxy', '3.3.0'
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
end