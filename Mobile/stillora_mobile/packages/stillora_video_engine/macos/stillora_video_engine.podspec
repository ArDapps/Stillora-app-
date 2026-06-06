#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stillora_video_engine.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stillora_video_engine'
  s.version          = '0.0.1'
  s.summary          = 'Native Stillora video export engine.'
  s.description      = <<-DESC
Native macOS video export for Stillora using AVFoundation and CoreGraphics.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Stillora' => 'support@stillora.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
