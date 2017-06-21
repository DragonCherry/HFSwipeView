//
//  ImageCirculatingController.swift
//  HFSwipeView_Example
//
//  Created by DragonCherry on 6/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import HFSwipeView
import TinyLog

class ImageCirculatingController: UIViewController {
    
    fileprivate let sampleCount: Int = 6
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
        return CGSize(width: 250, height: view.frame.size.width)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(swipeView)
        title = "Image"
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
        
        if let imageView = view as? UIImageView {
            if isCurrent {
                if imageView != currentView {
                    currentView?.backgroundColor = .clear
                }
                imageView.backgroundColor = .yellow
                currentView = imageView
                currentIndex = indexPath.row
            } else {
                imageView.backgroundColor = .clear
            }
            imageView.image = UIImage(named: "IMG_0\(indexPath.row + 1)")
            imageView.setBorder(1, color: .black)
            
            log("[\(indexPath.row)] -> isCurrent: \(isCurrent)")
        } else {
            assertionFailure("failed to retrieve UILabel for index: \(indexPath.row)")
        }
    }
}

// MARK: - HFSwipeViewDelegate
extension ImageCirculatingController: HFSwipeViewDelegate {
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
extension ImageCirculatingController: HFSwipeViewDataSource {
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize {
        return itemSize
    }
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int {
        return sampleCount
    }
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView {
        log("[\(indexPath.row)]")
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: itemSize))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
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
