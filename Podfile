platform :ios, '13.0'

use_frameworks!
inhibit_all_warnings!

target 'MobileWallet' do
  pod 'SwiftLint'
  pod 'Tor', '~> 407.11'
  pod 'FloatingPanel', '1.7.5'
  pod 'lottie-ios'
  pod 'SwiftEntryKit', '1.2.3'
  pod 'ReachabilitySwift'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.27.1'
  pod 'SwiftKeychainWrapper', '3.4.0'
  pod 'Giphy', '2.1.22'
  pod 'IPtProxy', '1.8.0'
  pod 'OpenSSL-Universal'
  pod 'Zip', '2.1.2'
  pod 'YatLib', '0.3.2'
  pod 'TariCommon', '0.2.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
    end
  end
end