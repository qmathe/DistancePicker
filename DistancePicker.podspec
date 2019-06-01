Pod::Spec.new do |s|

  s.name         = "DistancePicker"
  s.version      = "0.8.4"
  s.summary      = "UIKit control to select a distance with a pan gesture, written in Swift"
  s.description  = "DistancePicker is a custom UIKit control to select a distance with a pan gesture. It looks like a ruler with multiple distance marks and can be used to resize a map, set up a geofence or choose a search radius."
  s.homepage     = "https://github.com/qmathe/DistancePicker"
  s.screenshots  = "http://www.quentinmathe.com/github/DistancePicker/Add%20Place%20with%20Search%20Radius%20-%20iPhone%205.jpg"
  s.license      = "MIT"
  s.author             = { "Quentin Mathé" => "quentin.mathe@gmail.com" }
  s.social_media_url   = "http://twitter.com/quentin_mathe"

  s.swift_version = "4.2"
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/qmathe/DistancePicker.git", :tag => "0.8.4" }
  s.source_files = '*.swift', '*.{h,m}'
  s.public_header_files = "*.h"
  s.framework  = "MapKit"

end
