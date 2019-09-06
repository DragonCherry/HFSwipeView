# TinyLog
Very simple logging utility shows filename, function, and line with given message.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Sample / Result

```
// Sample code
log("Printing default log, and it's regarded as verbose log.")
logi("Printing information log.")
logv("Printing verbose log.")
logd("Printing debug log.")
logw("Printing warning log.")
loge("Printing error log.")
logc("Printing critical log.")
        
```

```
// Result
2017-01-11 15:03:54.691 ⚫ViewController.viewDidLoad:16 - Printing default log, and it's regarded as verbose log.
2017-01-11 15:03:54.693 💙ViewController.viewDidLoad:17 - Printing information log.
2017-01-11 15:03:54.693 ⚫ViewController.viewDidLoad:18 - Printing verbose log.
2017-01-11 15:03:54.693 💚ViewController.viewDidLoad:19 - Printing debug log.
2017-01-11 15:03:54.693 💛ViewController.viewDidLoad:20 - Printing warning log.
2017-01-11 15:03:54.693 ❤️ViewController.viewDidLoad:21 - Printing error log.
2017-01-11 15:03:54.693 💔ViewController.viewDidLoad:22 - Printing critical log.

```


## Requirements

N/A

## Installation

TinyLog is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TinyLog"
```

By including following script in your Podfile, you can enable logger in debug mode only. 

```

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'TinyLog'
            target.build_configurations.each do |config|
                if config.name == 'Debug'
                    config.build_settings['OTHER_SWIFT_FLAGS'] = '-D' 'DEBUG'
                else
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ''
                end
            end
        end
    end
end

```

## Author

DragonCherry, dragoncherry@naver.com

## License

Completely free to use for any purpose.
