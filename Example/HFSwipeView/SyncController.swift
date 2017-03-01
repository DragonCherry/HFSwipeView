//
//  SyncController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView
import TinyLog

class SyncController: UIViewController {
    
    // sample item count for two swipe view
    fileprivate let sampleCount: Int = 10
    fileprivate let kMultiTag: Int = 100
    fileprivate let kFullTag: Int = 101
    
    fileprivate var currentMultiView: UILabel?
    fileprivate var currentFullView: UILabel?
    
    // where multi swipe view will be placed
    fileprivate var multiViewRect: CGRect {
        return CGRect(x: 0, y: 64, width: self.view.frame.size.width, height: 50)
    }
    fileprivate var multiItemSize: CGSize {
        return CGSize(width: 100, height: multiViewRect.height)
    }
    
    // where full swipe view will be placed
    fileprivate var fullViewRect: CGRect {
        return CGRect(
            x: 0,
            y: multiViewRect.origin.y + multiViewRect.height,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height - (multiViewRect.origin.y + multiViewRect.height))
    }
    fileprivate var fullItemSize: CGSize {
        return CGSize(width: self.view.frame.size.width, height: fullViewRect.height)
    }
    
    fileprivate var swipeViewMulti: HFSwipeView!
    fileprivate var swipeViewFull: HFSwipeView!
    
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
        swipeViewFull.currentPageIndicatorTintColor = .black
        swipeViewFull.pageIndicatorTintColor = .lightGray
        swipeViewFull.backgroundColor = .clear
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
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        if swipeView.tag == kMultiTag {
            return multiItemSize
        } else {
            return fullItemSize
        }
    }
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
        if swipeView.tag == kMultiTag {
            return sampleCount
        } else {
            return sampleCount
        }
    }
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        
        var view: UIView!
        switch swipeView.tag {
        case kFullTag:
            let fullLabel = UILabel(frame: CGRect(origin: .zero, size: fullItemSize))
            fullLabel.text = "\(indexPath.row)"
            fullLabel.textAlignment = .center
            view = fullLabel
        case kMultiTag:
            // inner view with size
            let contentLabel = UILabel(frame: CGRect(origin: .zero, size: multiItemSize))
            contentLabel.text = "\(indexPath.row)"
            contentLabel.textAlignment = .center
            view = contentLabel
        default:
            assertionFailure("unknown tag: \(swipeView.tag)")
        }
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView) {
        if let label = view as? UILabel {
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: UIColor.black)
            label.superview?.setBorder(1, color: UIColor.black)
        } else {
            assertionFailure("failed to retrieve button for index: \(indexPath.row)")
        }
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
        if swipeView.tag == kMultiTag {
            currentMultiView?.setBorder(0.5, color: UIColor.black)
            currentMultiView = view as? UILabel
            currentMultiView?.text = "\(indexPath.row)"
            currentMultiView?.setBorder(1, color: UIColor.blue)
            currentMultiView?.superview?.setBorder(1, color: UIColor.black)
        } else {
            currentFullView?.setBorder(0.5, color: UIColor.black)
            currentFullView = view as? UILabel
            currentFullView?.text = "\(indexPath.row)"
            currentFullView?.setBorder(1, color: UIColor.blue)
            currentFullView?.superview?.setBorder(1, color: UIColor.black)
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension SyncController: HFSwipeViewDelegate {
    func swipeView(_ swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: IndexPath) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(_ swipeView: HFSwipeView, didSelectItemAtPath indexPath: IndexPath) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
    
    func swipeView(_ swipeView: HFSwipeView, didChangeIndexPath indexPath: IndexPath, changedView view: UIView) {
        NSLog("\(#function): HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
    }
}
