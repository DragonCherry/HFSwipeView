//
//  HFSwipeView+Utility.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit

// MARK: - Page Control
extension HFSwipeView {
    
    internal func moveRealPage(_ realPage: Int, animated: Bool) {
        if realPage >= 0 && realPage < realViewCount && realPage == currentRealPage {
            print("moveRealPage received same page(\(realPage)) == currentPage(\(currentRealPage))")
            return
        }
        print("[\(self.tag)]: \(realPage)")
        
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
            print("Failed to retrieve current view from indexViewMapper for indexPath: \(displayIndex.row)")
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
        print("[\(self.tag)]: real -> \(indexPath.row)")
    }
}
