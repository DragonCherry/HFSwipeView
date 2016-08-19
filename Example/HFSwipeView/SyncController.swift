//
//  SyncController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFUtility
import HFSwipeView

class SyncController: UIViewController {
    
    // sample item count for two swipe view
    private let sampleCount: Int = 10
    private let kMultiTag: Int = 100
    private let kFullTag: Int = 101
    
    private var currentMultiView: UILabel?
    private var currentFullView: UILabel?
    
    // where multi swipe view will be placed
    private var multiViewRect: CGRect {
        return CGRectMake(0, 64, self.view.width, 50)
    }
    private var multiItemSize: CGSize {
        return CGSize(width: 100, height: multiViewRect.height)
    }
    
    // where full swipe view will be placed
    private var fullViewRect: CGRect {
        return CGRectMake(
            0,
            multiViewRect.origin.y + multiViewRect.height,
            self.view.width,
            self.view.height - (multiViewRect.origin.y + multiViewRect.height))
    }
    private var fullItemSize: CGSize {
        return CGSize(width: self.view.width, height: fullViewRect.height)
    }
    
    private var swipeViewMulti: HFSwipeView!
    private var swipeViewFull: HFSwipeView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swipeViewMulti = HFSwipeView(frame: multiViewRect)
        swipeViewMulti.autoAlignEnabled = true
        swipeViewMulti.circulating = true
        swipeViewMulti.dataSource = self
        swipeViewMulti.delegate = self
        swipeViewMulti.tag = kMultiTag
        swipeViewMulti.recycleEnabled = true
        swipeViewMulti.pageControlHidden = true
        self.view.addSubview(self.swipeViewMulti!)
        
        swipeViewFull = HFSwipeView(frame: fullViewRect)
        swipeViewFull.autoAlignEnabled = true
        swipeViewFull.circulating = true
        swipeViewFull.dataSource = self
        swipeViewFull.delegate = self
        swipeViewFull.tag = kFullTag
        swipeViewFull.recycleEnabled = true
        swipeViewFull.currentPageIndicatorTintColor = UIColor.blackColor()
        swipeViewFull.pageIndicatorTintColor = UIColor.lightGrayColor()
        swipeViewFull.backgroundColor = UIColor.clearColor()
        self.view.addSubview(self.swipeViewFull!)
        
        swipeViewFull.syncView = swipeViewMulti
        swipeViewMulti.syncView = swipeViewFull
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.swipeViewFull.frame = fullViewRect
        self.swipeViewMulti.frame = multiViewRect
    }
}

// MARK: - HFSwipeViewDataSource
extension SyncController: HFSwipeViewDataSource {
    func swipeViewItemSize(swipeView: HFSwipeView) -> CGSize {
        if swipeView.tag == kMultiTag {
            return multiItemSize
        } else {
            return fullItemSize
        }
    }
    func swipeViewItemCount(swipeView: HFSwipeView) -> Int {
        if swipeView.tag == kMultiTag {
            return sampleCount
        } else {
            return sampleCount
        }
    }
    func swipeView(swipeView: HFSwipeView, viewForIndexPath indexPath: NSIndexPath) -> UIView {
        
        var view: UIView!
        switch swipeView.tag {
        case kFullTag:
            let fullLabel = UILabel(frame: CGRect(origin: CGPointZero, size: fullItemSize))
            fullLabel.text = "\(indexPath.row)"
            fullLabel.textAlignment = .Center
            view = fullLabel
        case kMultiTag:
            // inner view with size
            let contentLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: multiItemSize))
            contentLabel.text = "\(indexPath.row)"
            contentLabel.textAlignment = .Center
            view = contentLabel
        default:
            assertionFailure("unknown tag: \(swipeView.tag)")
        }
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        return view
    }
    func swipeView(swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        if let label = view as? UILabel {
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: UIColor.blackColor())
            label.superview?.setBorder(1, color: UIColor.blackColor())
        } else {
            assertionFailure("failed to retrieve button for index: \(indexPath.row)")
        }
    }
    func swipeView(swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
        if swipeView.tag == kMultiTag {
            currentMultiView?.setBorder(0.5, color: UIColor.blackColor())
            currentMultiView = view as? UILabel
            currentMultiView?.text = "\(indexPath.row)"
            currentMultiView?.setBorder(1, color: UIColor.blueColor())
            currentMultiView?.superview?.setBorder(1, color: UIColor.blackColor())
        } else {
            currentFullView?.setBorder(0.5, color: UIColor.blackColor())
            currentFullView = view as? UILabel
            currentFullView?.setBorder(1, color: UIColor.blueColor())
            currentFullView?.superview?.setBorder(1, color: UIColor.blackColor())
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension SyncController: HFSwipeViewDelegate {
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