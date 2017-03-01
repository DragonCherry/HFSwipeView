//
//  SimpleCirculatingController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView
import TinyLog

class SimpleCirculatingController: UIViewController {
    
    fileprivate let sampleCount: Int = 5
    fileprivate var swipeView: HFSwipeView!
    fileprivate var currentIndex: Int = 0
    fileprivate var currentView: UIView?
    fileprivate var itemSize: CGSize {
        return CGSize(width: 100, height: 100)
    }
    fileprivate var swipeViewFrame: CGRect {
        return CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: 100)
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
        view.addSubview(swipeView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.swipeView.frame = swipeViewFrame
        self.swipeView.setBorder(0.5, color: .black)
    }
    
    func updateCellView(_ view: UIView, indexPath: IndexPath, isCurrent: Bool) {
        
        if let label = view as? UILabel {
            if isCurrent {
                if label != currentView {
                    currentView?.backgroundColor = .clear
                }
                label.backgroundColor = .yellow
                currentView = label
                currentIndex = indexPath.row
            } else {
                label.backgroundColor = .clear
            }
            label.textAlignment = .center
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: .black)
            
            log("[\(indexPath.row)] -> isCurrent: \(isCurrent)")
        } else {
            assertionFailure("failed to retrieve UILabel for index: \(indexPath.row)")
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension SimpleCirculatingController: HFSwipeViewDelegate {
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

// MARK: - HFSwipeViewDataSource
extension SimpleCirculatingController: HFSwipeViewDataSource {
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        return itemSize
    }
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        log("[\(indexPath.row)]")
        return UILabel(frame: CGRect(origin: .zero, size: itemSize))
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView) {
        log("[\(indexPath.row)]")
        updateCellView(view, indexPath: indexPath, isCurrent: false)
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        log("[\(indexPath.row)]")
        updateCellView(view, indexPath: indexPath, isCurrent: true)
    }
}
