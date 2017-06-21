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
    
    fileprivate let sampleCount: Int = 3
    fileprivate var didSetupConstraints: Bool = false
    
    fileprivate lazy var swipeView: HFSwipeView = {
        let view = HFSwipeView.newAutoLayout()
        view.isDebug = true
        view.autoAlignEnabled = true
        view.circulating = true        // true: circulating mode
        view.dataSource = self
        view.delegate = self
        view.pageControlHidden = true
        view.currentPage = 0
        view.autoAlignEnabled = true
        return view
    }()
    fileprivate var currentIndex: Int = 0
    fileprivate var currentView: UIView?
    fileprivate var itemSize: CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(swipeView)
        title = "Circulating"
    }
    
    override func updateViewConstraints() {
        if !didSetupConstraints {
            swipeView.autoSetDimension(.height, toSize: itemSize.height)
            swipeView.autoPinEdge(toSuperviewEdge: .leading)
            swipeView.autoPinEdge(toSuperviewEdge: .trailing)
            swipeView.autoAlignAxis(toSuperviewAxis: .horizontal)
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.swipeView.setBorder(1, color: .black)
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
            label.setBorder(1, color: .black)
            
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
