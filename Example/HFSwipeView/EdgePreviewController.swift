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
    fileprivate var didSetupConstraints: Bool = false
    
    fileprivate var fullItemSize: CGSize {
        return CGSize(width: swipeView.frame.size.width - 70, height: swipeView.frame.size.height)
    }
    
    fileprivate lazy var swipeView: HFSwipeView = {
        let view = HFSwipeView.newAutoLayout()
        view.isDebug = true
        view.autoAlignEnabled = true
        view.circulating = true
        view.dataSource = self
        view.delegate = self
        view.recycleEnabled = true
        view.currentPage = 0
        view.currentPageIndicatorTintColor = UIColor.black
        view.pageIndicatorTintColor = UIColor.lightGray
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(swipeView)
    }
    
    override func updateViewConstraints() {
        if !didSetupConstraints {
            swipeView.autoMatch(.height, to: .height, of: self.view, withMultiplier: 0.8)
            swipeView.autoMatch(.width, to: .width, of: self.view)
            swipeView.autoPinEdge(toSuperviewEdge: .leading)
            swipeView.autoPinEdge(toSuperviewEdge: .trailing)
            swipeView.autoAlignAxis(toSuperviewAxis: .horizontal)
            didSetupConstraints = true
        }
        super.updateViewConstraints()
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
            label.setBorder(1, color: UIColor.black)
        } else {
            assertionFailure("failed to retrieve button for index: \(indexPath.row)")
        }
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        log("HFSwipeView(\(swipeView.tag)) -> \(indexPath.row)")
        currentFullView?.setBorder(0.5, color: UIColor.black)
        currentFullView = view as? UILabel
        currentFullView?.text = "\(indexPath.row)"
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
