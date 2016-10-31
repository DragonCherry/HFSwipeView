//
//  EdgePreviewController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFUtility
import HFSwipeView

class EdgePreviewController: UIViewController {
    
    // sample item count for two swipe view
    private let sampleCount: Int = 10
    private var currentFullView: UILabel?
    
    // where full swipe view will be placed
    private var fullViewRect: CGRect {
        return CGRectMake(
            0,
            100,
            self.view.frame.size.width,
            self.view.frame.size.width)
    }
    private var fullItemSize: CGSize {
        return CGSize(width: self.view.frame.size.width - 70, height: self.view.frame.size.width)
    }
    
    private var swipeView: HFSwipeView!
    
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
        swipeView.currentPageIndicatorTintColor = UIColor.blackColor()
        swipeView.pageIndicatorTintColor = UIColor.lightGrayColor()
        swipeView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(self.swipeView)
    }
}

// MARK: - HFSwipeViewDataSource
extension EdgePreviewController: HFSwipeViewDataSource {
    func swipeViewItemDistance(swipeView: HFSwipeView) -> CGFloat {
        return 15
    }
    func swipeViewItemSize(swipeView: HFSwipeView) -> CGSize {
        return fullItemSize
    }
    func swipeViewItemCount(swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(swipeView: HFSwipeView, viewForIndexPath indexPath: NSIndexPath) -> UIView {
        let fullLabel = UILabel(frame: CGRect(origin: CGPointZero, size: fullItemSize))
        fullLabel.text = "\(indexPath.row)"
        fullLabel.textAlignment = .Center
        return fullLabel
    }
    func swipeView(swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        if let label = view as? UILabel {
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: UIColor.blackColor())
        } else {
            assertionFailure("failed to retrieve button for index: \(indexPath.row)")
        }
    }
    func swipeView(swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
        currentFullView?.setBorder(0.5, color: UIColor.blackColor())
        currentFullView = view as? UILabel
        currentFullView?.setBorder(1, color: UIColor.blueColor())
    }
}

// MARK: - HFSwipeViewDelegate
extension EdgePreviewController: HFSwipeViewDelegate {
    func swipeView(swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: NSIndexPath) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(swipeView: HFSwipeView, didSelectItemAtPath indexPath: NSIndexPath) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(swipeView: HFSwipeView, didChangeIndexPath indexPath: NSIndexPath, changedView view: UIView) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
}