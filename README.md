Distance Picker
===============

[![Build Status](https://travis-ci.org/qmathe/DistancePicker.svg?branch=master)](https://travis-ci.org/qmathe/DistancePicker)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com)
[![Language Swift 2.2](https://img.shields.io/badge/Language-Swift%202.2-orange.svg?style=flat)](https://swift.org)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/tadija/FormTouch/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

DistancePicker is a custom UIKit control to select a distance with a pan gesture. 
It looks like a ruler with multiple distance marks. You can use it to set a 
search radius.

<img src="http://www.placeboardapp.com/images/Add%20Place%20with%20Search%20Radius%20-%20iPhone%205.jpg" height="700" alt="Screenshot" />

To see in action, take a look at [Placeboard](http://www.placeboardapp.com) demo video.

Compatibility
-------------

DistancePicker requires iOS 7 or higher and is written in Swift 2.2.

Installation
------------

Drop DistancePicker.swift in your Xcode project, copy the content of DistancePicker-Bridging-Header.h into your project bridging header and link MapKit.

**Note:** If you don't use a bridging header, you must create one and declare it in Build Settings > Swift Compiler - Code Generation > Objective-C Bridging Header.
