# Uncomment the next line to define a global platform for your project
# platform :osx, '12.0'
# platform :ios, '14.1'

# ignore all warnings from all pods
inhibit_all_warnings!

def shared_pods
#  pod 'BikeBLEKit', :path => '/Users/yves/Project/BLEManager_Mobile_SDK/BikeBLEKit', :inhibit_warnings => true
  pod 'BikeBLEKit', :git => "git@github.com:FarmlandTech/BLEManager_Mobile_SDK.git", :branch => 'feature-jeff', :inhibit_warnings => true
  pod "AppleDevKit/Common", :git => "git@github.com:FarmlandTech/AppleDevKit.git", :branch => 'dev', :inhibit_warnings => true
end

target 'AppleBLEKit' do
  platform :ios, '14.1'

  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AppleBLEKit
  shared_pods
end

target 'AppleBLEKit_Simulator' do
  platform :ios, '14.1'

  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AppleBLEKit
  shared_pods
end
