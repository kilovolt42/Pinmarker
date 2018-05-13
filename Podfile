platform :ios, '11.0'
inhibit_all_warnings!

target 'Pinmarker' do
  use_frameworks!
  pod 'Lockbox'
  pod 'RNCryptor-objc'
  pod 'TinyKeychain'
end

target 'PinmarkerTests' do
    use_frameworks!
    pod 'Lockbox'
    pod 'RNCryptor-objc'
    pod 'TinyKeychain'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      target.build_settings(configuration.name)['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
