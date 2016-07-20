#
# Be sure to run `pod lib lint HFSwipeView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HFSwipeView'
  s.version          = '0.1.7'
  s.summary          = 'Infinite SwipeView for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Swipe view loop through multiple view items infinitely, with UIPageControl attached.'
  s.homepage         = 'https://github.com/DragonCherry/HFSwipeView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DragonCherry' => 'mcpdragon@daum.net' }
  s.source           = { :git => 'https://github.com/DragonCherry/HFSwipeView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'HFSwipeView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HFSwipeView' => ['HFSwipeView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'HFUtility'

end
