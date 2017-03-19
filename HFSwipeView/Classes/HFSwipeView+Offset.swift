//
//  HFSwipeView+Offset.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - Private Methods: Offset Control
extension HFSwipeView {
    
    internal var centerOffset: CGPoint {
        var center = self.collectionView.contentOffset
        center.x += frame.size.width / 2
        return center
    }
    
    internal func centeredOffsetForIndex(_ indexPath: IndexPath) -> CGPoint {
        var newX: CGFloat = 0
        if circulating {
            let cellWidth = itemSpace + cgfloat(itemSize?.width)
            newX += cellWidth * cgfloat(indexPath.row as AnyObject?)
            newX -= (frame.size.width - cellWidth) / 2
        } else {
            let cellWidth = itemSpace + cgfloat(itemSize?.width)
            let cellSpace = cellWidth * cgfloat(indexPath.row)
            newX = cellSpace - (frame.size.width - cellWidth) / 2
            if newX < 0 {
                newX = 0
            }
            if newX > collectionView.contentSize.width - frame.size.width {
                newX = collectionView.contentSize.width - frame.size.width
            }
        }
        
        // corrected index
        let centeredOffset = CGPoint(x: flippedX(newX), y: collectionView.frame.origin.y)
        return centeredOffset
    }
    
    internal func centeredOffsetForDefaultOffset(_ proposedOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        // corrected index
        guard let proposedIndexPath = indexPathForItemAtPoint(proposedOffset) else {
            loge("nearestIndexPath is nil")
            return .zero
        }
        
        if !circulating && proposedOffset.x == 0 {
            // when bouncing on left
            return proposedOffset
        } else {
            let centeredOffset = centeredOffsetForIndex(proposedIndexPath)
            let centeredIndexPath = indexPathForItemAtPoint(centeredOffset)
            let currentIndex = integer(indexPathForItemAtPoint(CGPoint(x: collectionView.contentOffset.x, y: 0))?.row)
            if integer(centeredIndexPath?.row) == currentIndex {
                if isRtl {
                    if velocity.x > 0 {
                        return centeredOffsetForIndex(IndexPath(item: currentIndex - 1, section: 0))
                    } else if velocity.x < 0 {
                        return centeredOffsetForIndex(IndexPath(item: currentIndex + 1, section: 0))
                    } else {
                        return proposedOffset
                    }
                } else {
                    if velocity.x < 0 {
                        return centeredOffsetForIndex(IndexPath(item: currentIndex - 1, section: 0))
                    } else if velocity.x > 0 {
                        return centeredOffsetForIndex(IndexPath(item: currentIndex + 1, section: 0))
                    } else {
                        return proposedOffset
                    }
                }
            } else {
                return centeredOffset
            }
        }
    }
    
    internal func setContentOffsetWithoutCallingDelegate(_ contentOffset: CGPoint) {
        collectionView.delegate = nil
        collectionView.contentOffset = contentOffset
        collectionView.delegate = self
    }
    
    internal func setContentSizeWithoutCallingDelegate(_ contentSize: CGSize) {
        collectionView.delegate = nil
        collectionView.contentSize = contentSize
        collectionView.delegate = self
    }
    
    internal func scrollViewFixOffset(_ scrollView: UIScrollView) -> Bool {
        let offset = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        if offset.x < dummyWidth {
            let delta = dummyWidth - offset.x
            setContentOffsetWithoutCallingDelegate(CGPoint(x: contentSize.width - dummyWidth - delta, y: 0))
            log("[\(self.tag)]: moved to last view, offset: \(scrollView.contentOffset)")
            return true
        } else if offset.x >= contentSize.width - dummyWidth {
            let delta = offset.x - (contentSize.width - dummyWidth)
            setContentOffsetWithoutCallingDelegate(CGPoint(x: self.dummyWidth + delta, y: 0))
            log("[\(self.tag)]: moved to first view!, offset: \(scrollView.contentOffset)")
            return true
        }
        return false
    }
}
