Pod::Spec.new do |s|
  s.name         = "GYBootingProtection"
  s.version      = "1.0"
  s.summary      = "A short description of GYBootingProtection."
  s.description  = <<-DESC
                   DESC
  s.homepage     = "https://github.com/liuslevis/GYBootingProtection.git"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/liuslevis/GYBootingProtection.git", :tag => "#{1.0}" }
  s.source_files  = "src/*.{h,m}"
  s.public_header_files = "src/AppDelegate.h"

end
