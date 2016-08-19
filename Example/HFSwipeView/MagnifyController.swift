//
//  MagnifyController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFUtility
import HFSwipeView

class MagnifyController: UIViewController {
    
    private let sampleCount: Int = 5
    private var swipeView: HFSwipeView!
    private var currentView: UIView?
    private var itemSize: CGSize {
        return CGSizeMake(70, 70)
    }
    private var swipeViewFrame: CGRect {
        return CGRectMake(0, 100, view.width, 100)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swipeView = HFSwipeView(frame: swipeViewFrame)
        swipeView.autoAlignEnabled = true
        swipeView.circulating = true        // true: circulating mode
        swipeView.dataSource = self
        swipeView.delegate = self
        swipeView.pageControlHidden = true
        swipeView.currentPage = 0
        swipeView.magnifyCenter = true
        swipeView.preferredMagnifyBonusRatio = 1.5
        view.addSubview(swipeView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.swipeView.frame = swipeViewFrame
        self.swipeView.setBorder(0.5, color: .blackColor())
    }
    
    func updateCellView(view: UIView, indexPath: NSIndexPath, isCurrent: Bool) {
        
        if let label = view as? UILabel {
            
            if isCurrent {
                // old view
                currentView?.backgroundColor = .whiteColor()
                currentView = label
                currentView?.backgroundColor = .yellowColor()
            } else {
                label.backgroundColor = .whiteColor()
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
extension MagnifyController: HFSwipeViewDelegate {
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
extension MagnifyController: HFSwipeViewDataSource {
    func swipeViewItemDistance(swipeView: HFSwipeView) -> CGFloat {
        return 30   // left pad 15 + right pad 15
    }
    func swipeViewItemSize(swipeView: HFSwipeView) -> CGSize {
        // view [pad 15 + width 70 + pad 15] -> displays 100 width of cell
        return CGSize(width: 70, height: 100)
    }
    func swipeViewItemCount(swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(swipeView: HFSwipeView, viewForIndexPath indexPath: NSIndexPath) -> UIView {
        let contentLabel = UILabel(frame: CGRect(origin: CGPointMake(0, 15), size: CGSizeMake(70, 70)))
        contentLabel.text = "\(indexPath.row)"
        contentLabel.textAlignment = .Center
        contentLabel.layer.cornerRadius = 35
        contentLabel.layer.masksToBounds = true
        return contentLabel
    }
    func swipeView(swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: false)
    }
    func swipeView(swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: NSIndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: true)
    }
}