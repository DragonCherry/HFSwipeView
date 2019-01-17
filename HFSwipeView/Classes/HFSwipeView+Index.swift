//
//  HFSwipeView+Index.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - Index Control
extension HFSwipeView {
    
    internal func closestIndexTo(_ displayIndex: IndexPath) -> IndexPath {
        
        let from = currentRealPage
        let dest = displayIndex.row
        var minDiff: Int = count + dummyCount * 2
        var minIdx: Int = -1
        var index = count - dummyCount
        
        // traverse left
        let traverseLeft = {
            for i in 0..<self.dummyCount {
                if dest == index {
                    let newDiff = from > i ? from - i : i - from
                    if newDiff < minDiff {
                        minDiff = newDiff
                        minIdx = i
                    }
                }
                index += 1
            }
            index = 0
        }
        
        // traverse body
        let traverseBody = {
            for i in self.dummyCount..<(self.dummyCount + self.count) {
                if dest == index {
                    let newDiff = from > i ? from - i : i - from
                    if newDiff < minDiff {
                        minDiff = newDiff
                        minIdx = i
                    }
                }
                index += 1
            }
            index = 0
        }
        
        // traverse right
        let traverseRight = {
            for i in (self.dummyCount + self.count)..<(self.count + self.dummyCount * 2) {
                if dest == index {
                    let newDiff = from > i ? from - i : i - from
                    if newDiff < minDiff {
                        minDiff = newDiff
                        minIdx = i
                    }
                }
                index += 1
            }
        }
        
        if isRtl {
            traverseLeft()
            traverseBody()
            if minIdx < 0 {
                traverseRight()
            }
        } else {
            traverseRight()
            traverseBody()
            if minIdx < 0 {
                traverseLeft()
            }
        }
        
        log("[\(self.tag)]: from: \(from) to: \(minIdx)")
        return IndexPath(item: minIdx, section: 0)
    }
    
    internal func indexPathForItemAtPoint(_ offset: CGPoint) -> IndexPath? {
        
        if isRtl {
            let rightEdge = collectionView.contentOffset.x + collectionView.frame.size.width
            var index: IndexPath? = nil
            let center = centerOffset
            
            if offset.x < 0 {
                // left edge
                index = IndexPath(row: count - 1, section: 0)
            } else if rightEdge > collectionView.contentSize.width {
                // right edge
                index = IndexPath(row: 0, section: 0)
            } else {
                // between both side
                index = collectionView.indexPathForItem(at: center)
            }
            return index
        } else {
            let rightEdge = collectionView.contentOffset.x + collectionView.frame.size.width
            var index: IndexPath? = nil
            let center = centerOffset
            
            if offset.x < 0 {
                // left edge
                index = IndexPath(row: 0, section: 0)
            } else if rightEdge > collectionView.contentSize.width {
                // right edge
                index = IndexPath(row: count - 1, section: 0)
            } else {
                // between both side
                index = collectionView.indexPathForItem(at: center)
            }
            return index
        }
    }
    
    internal func displayIndexUsing(_ realIndex: IndexPath) -> IndexPath {
        if circulating {
            var displayIndex = 0
            if realIndex.row < dummyCount {
                displayIndex = realIndex.row - dummyCount + count
            } else if realIndex.row < count + dummyCount {
                displayIndex = realIndex.row - dummyCount
            } else {
                displayIndex = realIndex.row - count - dummyCount
            }
            log("[\(self.tag)]: \(realIndex.row) -> \(displayIndex)")
            return IndexPath(item: displayIndex, section: 0)
        } else {
            return IndexPath(item: realIndex.row, section: 0)
        }
    }
    
    internal func realIndexUsing(_ displayIndex: IndexPath) -> IndexPath {
        if !circulating {
            return displayIndex
        }
        var index: Int = 0
        if 0 <= displayIndex.row && displayIndex.row < count {
            index = displayIndex.row + dummyCount
        }
        log("[\(self.tag)]: \(displayIndex.row) -> \(index)")
        return IndexPath(item: index, section: 0)
    }
    
    internal func realIndexesUsing(_ displayIndex: IndexPath) -> [IndexPath] {
        if !circulating {
            return [displayIndex]
        }
        var realIndexes = [IndexPath]()
        
        let cut = count - dummyCount
        
        // index on dummy(head) area
        if displayIndex.row - cut >= 0 {
            realIndexes.append(IndexPath(item: displayIndex.row - cut, section: 0))
        }
        // index on center area
        realIndexes.append(IndexPath(item: dummyCount + displayIndex.row, section: 0))
        
        // index on dummy(tail) area
        if dummyCount + count + displayIndex.row < realViewCount {
            realIndexes.append(IndexPath(item: dummyCount + count + displayIndex.row, section: 0))
        }
        
        return realIndexes
    }
    
    internal func updateIndexBasedOnContentOffset() {
        
        if !circulating {
            return
        }
        
        guard let indexPath = indexPathForItemAtPoint(collectionView.contentOffset) else {
            logw("indexPathForItemAtPoint returned nil.")
            return
        }
        
        let displayIndex = displayIndexUsing(indexPath)
        let oldPage = currentRealPage
        
        currentPage = displayIndex.row
        currentRealPage = indexPath.row
        
        if oldPage != currentRealPage {
            pageControl.currentPage = displayIndex.row
            delegate?.swipeView?(self, didChangeIndexPath: displayIndex)
            if let view = indexViewMapper[currentRealPage] {
                dataSource?.swipeView?(self, needUpdateCurrentViewForIndexPath: displayIndex, view: view)
            } else {
                logw("Failed to retrieve current view from indexViewMapper for indexPath: \(indexPath.row)")
            }
            log("[\(self.tag)]: \(currentPage)/\(count - 1) - \(currentRealPage)/\(realViewCount - 1)")
        }
    }
    
    internal func finishScrolling() {
        
        guard let indexPath = indexPathForItemAtPoint(collectionView.contentOffset) else {
            return
        }
        log("[\(self.tag)]: real -> \(indexPath.row)")
        
        let displayIndex = displayIndexUsing(indexPath)
        delegate?.swipeView?(self, didFinishScrollAtIndexPath: displayIndex)
        
        if circulating {
            if !scrollViewFixOffset(collectionView) {
                autoAlign(collectionView, indexPath: indexPath)
            }
        } else {
            autoAlign(collectionView, indexPath: indexPath)
        }
        
        if circulating {
            resumeAutoSlide()
        }
    }
}
