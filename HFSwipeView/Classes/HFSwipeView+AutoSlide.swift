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
    public func startAutoSlide(forTimeInterval timeInterval: TimeInterval) {
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if timeInterval > 0 {
            stopAutoSlide()
            autoSlideInterval = timeInterval
            autoSlideTimer = Timer.scheduledTimer(
                timeInterval: timeInterval,
                target: self,
                selector: #selector(HFSwipeView.autoSlideCallback(_:)),
                userInfo: nil,
                repeats: true)
        }
    }
    
    public func pauseAutoSlide() {
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
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if autoSlideIntervalBackupForLaterUse > 0 {
            startAutoSlide(forTimeInterval: autoSlideIntervalBackupForLaterUse)
        }
    }
    
    public func stopAutoSlide() {
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
        guard count != 0 else {
            return
        }
        DispatchQueue.main.async {
            self.movePage((self.currentPage + 1) % self.count, animated: true)
        }
    }
}
