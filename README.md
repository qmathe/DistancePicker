Distance Picker
===============

[![Build Status](https://travis-ci.org/qmathe/DistancePicker.svg?branch=master)](https://travis-ci.org/qmathe/DistancePicker)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com)
[![Language Swift 2.2](https://img.shields.io/badge/Language-Swift%202.2-orange.svg?style=flat)](https://swift.org)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/qmathe/DistancePicker/LICENSE)

DistancePicker is a custom UIKit control to select a distance with a pan gesture. It looks like a ruler with multiple distance marks and can be used to resize a map, set up a geofence or choose a search radius.

<img src="http://www.placeboardapp.com/images/Add%20Place%20with%20Search%20Radius%20-%20iPhone%205.jpg" height="700" alt="Screenshot" />

To see in action, take a look at [Placeboard](http://www.placeboardapp.com) demo video.

Compatibility
-------------

DistancePicker requires iOS 7 or higher and is written in Swift 2.2.

**Note**: If you use Carthage, CocoaPods or manually install it as a framework, iOS 8 is required.

Installation
------------

### Carthage

Add the following line to your Cartfile, run `carthage update` to build the framework and drag the built DistancePicker.framework into your Xcode project.

    github "qmathe/DistancePicker"
	
### CocoaPods

Add the following lines to your Podfile and run `pod install` with CocoaPods 0.36 or newer.

	use_frameworks!
	
	pod "DistancePicker"

### Manually

If you don't use Carthage or CocoaPods, it's possible to drag the built framework or embed the source files into your project.

#### Framework

Build DistancePicker framework and drop it into your Xcode project.

#### Files

Drop DistancePicker.swift and UIGestureRecognizer+MissingPublicAPI.h into your Xcode project, add `#import <DistancePicker/UIGestureRecognizer+MissingPublicAPI.h>` to your bridging header and link MapKit.

**Note:** If you don't use a bridging header, you must create one and declare it in Build Settings > Swift Compiler - Code Generation > Objective-C Bridging Header.
