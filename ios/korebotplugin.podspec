#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint korebotplugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'korebotplugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  s.source_files = ["Classes/**/*","BotSDK/**/*.{h,m,mm,swift,gif}", "KoreBotSDK/**/*.{h,m,swift,gif}", "BotSDK/Widgets/**/*.{h,m,txt,swift}"]
  
  s.dependency 'Starscream'
  s.dependency 'Alamofire','~> 5.0.0-beta.5'
  s.dependency 'AlamofireObjectMapper'
end
