Pod::Spec.new do |s|
  s.name         = "GYBootingProtection"
<<<<<<< HEAD
  s.version      = "0.0.1"
  s.summary      = "A iOS tool for detecting and protecting continuous launch crash."
  s.homepage     = "https://github.com/liuslevis/GYBootingProtection"
  s.license      = "MIT (example)"
  s.author             = { "David X. Lau" => "" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "http://github.com/liuslevis/GYBootingProtection.git", :tag => "0.0.1" }
  s.source_files  = "src"
=======
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

>>>>>>> 2aefe39024062994d84f406f64e69b0777a081dd
end
