//
//  HFSwipeView+Index.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - Auto Slide
extension HFSwipeView {
    /// zero or minus interval disables auto slide.
    public func startAutoSlideForTimeInterval(_ interval: TimeInterval) {
        log("")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if interval > 0 {
            stopAutoSlide()
            autoSlideInterval = interval
            autoSlideTimer = Timer.scheduledTimer(
                timeInterval: interval,
                target: self,
                selector: #selector(HFSwipeView.autoSlideCallback(_:)),
                userInfo: nil,
                repeats: true)
        }
    }
    
    public func pauseAutoSlide() {
        log("")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if autoSlideInterval > 0 {
            autoSlideIntervalBackupForLaterUse = autoSlideInterval
        }
        autoSlideInterval = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    public func resumeAutoSlide() {
        log("")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if autoSlideIntervalBackupForLaterUse > 0 {
            startAutoSlideForTimeInterval(autoSlideIntervalBackupForLaterUse)
        }
    }
    
    public func stopAutoSlide() {
        log("")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        autoSlideInterval = -1
        autoSlideIntervalBackupForLaterUse = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    public func autoSlideCallback(_ timer: Timer) {
        DispatchQueue.main.async {
            self.movePage((self.currentPage + 1) % self.count, animated: true)
        }
    }
}
