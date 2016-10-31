//
//  SimpleController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView

class SimpleController: UIViewController {
    
    private let sampleCount: Int = 10
    private var swipeView: HFSwipeView!
    private var currentView: UIView?
    private var itemSize: CGSize {
        return CGSizeMake(100, 100)
    }
    private var swipeViewFrame: CGRect {
        return CGRectMake(0, 100, self.view.frame.size.width, 100)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swipeView = HFSwipeView(frame: swipeViewFrame)
        swipeView.autoAlignEnabled = true
        swipeView.circulating = false
        swipeView.dataSource = self
        swipeView.delegate = self
        swipeView.pageControlHidden = true
        view.addSubview(swipeView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.swipeView!.frame = swipeViewFrame
    }
    
    func updateCellView(view: UIView, indexPath: NSIndexPath, isCurrent: Bool) {
        
        if let label = view as? UILabel {
            
            label.backgroundColor = isCurrent ? .yellowColor() : .whiteColor()
            
            if isCurrent {
                // old view
                currentView?.backgroundColor = .whiteColor()
                currentView = label
            }
            
            label.textAlignment = .Center
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: .blackColor())
            
            
            
        } else {
            assertionFailure("failed to retrieve UILabel for index: \(indexPath.row)")
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension SimpleController: HFSwipeViewDelegate {
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

// MARK: - HFSwipeViewDataSource
extension SimpleController: HFSwipeViewDataSource {
    func swipeViewItemSize(swipeView: HFSwipeView) -> CGSize {
        return itemSize
    }
    func swipeViewItemCount(swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(swipeView: HFSwipeView, viewForIndexPath indexPath: NSIndexPath) -> UIView {
        return UILabel(frame: CGRect(origin: CGPointZero, size: itemSize))
    }
    func swipeView(swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: false)
    }
    func swipeView(swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: true)
    }
}