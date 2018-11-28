#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'iap'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin to access iOS StoreKit library from Dart.'
  s.description      = <<-DESC
Flutter plugin to access iOS StoreKit library from Dart.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anatoly Pulyaevskiy' => 'anatoly.pulyaevskiy@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
end
