//
//  HFSwipeView+Utility.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - Page Control
extension HFSwipeView {
    
    internal func moveRealPage(_ realPage: Int, animated: Bool) {
        if realPage >= 0 && realPage < realViewCount && realPage == currentRealPage {
            log("moveRealPage received same page(\(realPage)) == currentPage(\(currentRealPage))")
            return
        }
        log("[\(self.tag)]: \(realPage)")
        
        let realIndex = IndexPath(item: realPage, section: 0)
        
        if autoAlignEnabled {
            let offset = centeredOffsetForIndex(realIndex)
            collectionView.setContentOffset(offset, animated: animated)
        }
        
        if !circulating {
            updateCurrentView(displayIndexUsing(realIndex))
        }
    }
    
    internal func updateCurrentView(_ displayIndex: IndexPath) {
        currentPage = displayIndex.row
        currentRealPage = displayIndex.row
        if let view = indexViewMapper[currentRealPage] {
            dataSource?.swipeView?(self, needUpdateCurrentViewForIndexPath: displayIndex, view: view)
        } else {
            logw("Failed to retrieve current view from indexViewMapper for indexPath: \(displayIndex.row)")
        }
        
    }
    
    internal func autoAlign(_ scrollView: UIScrollView, indexPath: IndexPath) {
        if autoAlignEnabled {
            if !circulating {
                let offset = scrollView.contentOffset
                if offset.x > 0 && offset.x < scrollView.contentSize.width - frame.size.width {
                    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                }
            } else {
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
        log("[\(self.tag)]: real -> \(indexPath.row)")
    }
}
