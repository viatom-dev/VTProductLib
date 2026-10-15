Pod::Spec.new do |spec|
  spec.name         = "VTMProductLib"
  spec.version      = "1.5.7"
  spec.summary      = "Support Lepu's products."
  spec.description  = <<-DESC
                  Support communication between Lepu's products and iOS devices.
                   DESC
  spec.homepage     = "https://github.com/viatom-dev/VTProductLib"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "yangweichao" => "yangweichao@lepucloud.com"}
  spec.source       = {
        :git => "https://github.com/viatom-dev/VTProductLib.git",
        :tag => spec.version
    }
  spec.ios.deployment_target = "11.0"
  spec.vendored_frameworks = "VTMProductLib.xcframework"
  # The framework is static and partly Objective-C++; consumers need the C++ stdlib.
  spec.libraries = 'c++', 'stdc++'
  spec.public_header_files = "VTMProductLib.xcframework/ios-arm64/VTMProductLib.framework/Headers/*.h"
  spec.source_files = "VTMProductLib.xcframework/**/Headers/*.h"
end
