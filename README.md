# HFSwipeView

[![CI Status](http://img.shields.io/travis/DragonCherry/HFSwipeView.svg?style=flat)](https://travis-ci.org/DragonCherry/HFSwipeView)
[![Version](https://img.shields.io/cocoapods/v/HFSwipeView.svg?style=flat)](http://cocoapods.org/pods/HFSwipeView)
[![License](https://img.shields.io/cocoapods/l/HFSwipeView.svg?style=flat)](http://cocoapods.org/pods/HFSwipeView)
[![Platform](https://img.shields.io/cocoapods/p/HFSwipeView.svg?style=flat)](http://cocoapods.org/pods/HFSwipeView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

If you wanna check how it works, click link below and press - "Tap to Play".
https://www.cocoacontrols.com/controls/hfswipeview

A swipe view loops through multiple view items infinitely, with UIPageControl attached. It's very similar to ViewPager from android but it also supports circulation between multiple views. In circulating mode(infinite loop), it will automatically locates current view at the center of swipe view.

Any advice and suggestions will be greatly appreciated.

## Features

- supports circulating mode(inifinite loop)

- supports auto-align selected cell on center of the view

- supports sync mode between two HFSwipeView(normally used for categorized header/content view)

- supports auto-slide(in circulating mode only) based on given NSTimeInterval, you can use it like banner-style view.

- supports magnifying mode(magnifies selected-center cell)

- supports auto shrinking UIPageControl at the bottom area of the HFSwipeView

## Requirements

Xcode8, Swift 3

## Version

for Swift 2.#, refer to version 1.0.0

after Swift 3.#, refer to development/master branch or last released version.

## Installation

HFSwipeView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "HFSwipeView"
```

## Author

DragonCherry, dragoncherry@naver.com

## License

HFSwipeView is available under the MIT license. See the LICENSE file for more info.
