//
//  EdgePreviewController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView
import TinyLog

class EdgePreviewController: UIViewController {
    
    // sample item count for two swipe view
    fileprivate let sampleCount: Int = 10
    fileprivate var currentFullView: UILabel?
    
    // where full swipe view will be placed
    fileprivate var fullViewRect: CGRect {
        return CGRect(
            x: 0,
            y: 100,
            width: self.view.frame.size.width,
            height: self.view.frame.size.width)
    }
    fileprivate var fullItemSize: CGSize {
        return CGSize(width: self.view.frame.size.width - 70, height: self.view.frame.size.width)
    }
    
    fileprivate var swipeView: HFSwipeView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swipeView = HFSwipeView(frame: fullViewRect)
        swipeView.autoAlignEnabled = true
        swipeView.circulating = true
        swipeView.dataSource = self
        swipeView.delegate = self
        swipeView.recycleEnabled = true
        swipeView.currentPage = 0
        swipeView.currentPageIndicatorTintColor = UIColor.black
        swipeView.pageIndicatorTintColor = UIColor.lightGray
        swipeView.backgroundColor = UIColor.clear
        self.view.addSubview(self.swipeView)
    }
}

// MARK: - HFSwipeViewDataSource
extension EdgePreviewController: HFSwipeViewDataSource {
    func swipeViewItemDistance(_ swipeView: HFSwipeView) -> CGFloat {
        return 15
    }
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        return fullItemSize
    }
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        let fullLabel = UILabel(frame: CGRect(origin: .zero, size: fullItemSize))
        fullLabel.text = "\(indexPath.row)"
        fullLabel.textAlignment = .center
        return fullLabel
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView) {
        if let label = view as? UILabel {
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: UIColor.black)
        } else {
            assertionFailure("failed to retrieve button for index: \(indexPath.row)")
        }
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
        currentFullView?.setBorder(0.5, color: UIColor.black)
        currentFullView = view as? UILabel
        currentFullView?.setBorder(1, color: UIColor.blue)
    }
}

// MARK: - HFSwipeViewDelegate
extension EdgePreviewController: HFSwipeViewDelegate {
    func swipeView(_ swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: IndexPath) {
        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(_ swipeView: HFSwipeView, didSelectItemAtPath indexPath: IndexPath) {
        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(_ swipeView: HFSwipeView, didChangeIndexPath indexPath: IndexPath, changedView view: UIView) {
        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
}
