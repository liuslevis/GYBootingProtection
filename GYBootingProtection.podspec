Pod::Spec.new do |s|
  s.name         = "GYBootingProtection"
  s.version      = "1.0"
  s.summary      = "A iOS tool for detecting and protecting continuous launch crash."
  s.homepage     = "https://github.com/liuslevis/GYBootingProtection"
  s.author             = { "David X. Lau" => "" }
  s.description  = <<-DESC
  see github page
                   DESC
  s.license      = "MIT"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/liuslevis/GYBootingProtection.git", :tag => "#{1.0}" }
  s.source_files  = "src/*.{h,m}"
  s.public_header_files = "src/AppDelegate.h"
end
