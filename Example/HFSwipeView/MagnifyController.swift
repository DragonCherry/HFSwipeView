//
//  MagnifyController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView
import TinyLog

class MagnifyController: UIViewController {
    
    fileprivate let sampleCount: Int = 5
    fileprivate var swipeView: HFSwipeView!
    fileprivate var currentView: UIView?
    fileprivate var itemSize: CGSize {
        return CGSize(width: 70, height: 70)
    }
    fileprivate var swipeViewFrame: CGRect {
        return CGRect(x: 0, y: 100, width: view.frame.size.width, height: 100)
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
        self.swipeView.setBorder(0.5, color: .black)
    }
    
    func updateCellView(_ view: UIView, indexPath: IndexPath, isCurrent: Bool) {
        
        if let label = view as? UILabel {
            
            if isCurrent {
                // old view
                currentView?.backgroundColor = .white
                currentView = label
                currentView?.backgroundColor = .yellow
            } else {
                label.backgroundColor = .white
            }
            
            label.textAlignment = .center
            label.text = "\(indexPath.row)"
            label.setBorder(0.5, color: .black)
            
        } else {
            assertionFailure("failed to retrieve UILabel for index: \(indexPath.row)")
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension MagnifyController: HFSwipeViewDelegate {
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
extension MagnifyController: HFSwipeViewDataSource {
    func swipeViewItemDistance(_ swipeView: HFSwipeView) -> CGFloat {
        return 30   // left pad 15 + right pad 15
    }
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        // view [pad 15 + width 70 + pad 15] -> displays 100 width of cell
        return CGSize(width: 70, height: 100)
    }
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        let contentLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 15), size: CGSize(width: 70, height: 70)))
        contentLabel.text = "\(indexPath.row)"
        contentLabel.textAlignment = .center
        contentLabel.layer.cornerRadius = 35
        contentLabel.layer.masksToBounds = true
        return contentLabel
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: false)
    }
    func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView) {
        updateCellView(view, indexPath: indexPath, isCurrent: true)
    }
}
