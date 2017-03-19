//
//  HFSwipeView+Delegate.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - UICollectionViewDataSource
extension HFSwipeView: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        log(": \(realViewCount)")
        return realViewCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if circulating {
            return cellForItemInCirculationMode(collectionView, indexPath: indexPath)
        } else {
            return cellForItemInNormalMode(collectionView, indexPath: indexPath)
        }
    }
    
    internal func cellForItemInCirculationMode(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: kSwipeViewCellIdentifier, for: indexPath)
        guard let dataSource = self.dataSource else {
            loge("dataSource is nil")
            return cell
        }
        
        let displayIndex: IndexPath = displayIndexUsing(indexPath)
        
        var cellView: UIView? = nil
        if recycleEnabled {
            if let view = cell.contentView.viewWithTag(kSwipeViewCellContentTag) {
                cellView = view
            } else {
                // set cellView as newly created view
                cellView = dataSource.swipeView(self, viewForIndexPath: displayIndex)
                cellView!.tag = kSwipeViewCellContentTag
                cell.contentView.addSubview(cellView!)
            }
        } else {
            cell.contentView.viewWithTag(kSwipeViewCellContentTag)?.removeFromSuperview()
            cellView = dataSource.swipeView(self, viewForIndexPath: displayIndex)
            cellView!.tag = kSwipeViewCellContentTag
            cell.contentView.addSubview(cellView!)
        }
        indexViewMapper[indexPath.row] = cellView
        
        // locate content view at center of given cell
        cellView!.frame.origin.x = itemSpace / 2
        
        if magnifyCenter {
            cell.tag = indexPath.row
            applyMagnifyCenter(forCell: cell)
        }
        
        if displayIndex.row == currentPage {
            log("[CURRENT][\(displayIndex.row)/\(indexPath.row)]")
            if indexPath.row == currentRealPage {
                dataSource.swipeView?(self, needUpdateCurrentViewForIndexPath: displayIndex, view: cellView!)
            } else {
                log("[NORMAL][\(displayIndex.row)/\(indexPath.row)]")
                dataSource.swipeView?(self, needUpdateViewForIndexPath: displayIndex, view: cellView!)
            }
        } else {
            log("[NORMAL][\(displayIndex.row)/\(indexPath.row)]")
            dataSource.swipeView?(self, needUpdateViewForIndexPath: displayIndex, view: cellView!)
        }
        addDebugInfo(view: cellView!, realIndex: indexPath.row, dispIndex: displayIndex.row)
        return cell
    }
    
    internal func cellForItemInNormalMode(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: kSwipeViewCellIdentifier, for: indexPath)
        guard let dataSource = self.dataSource else {
            loge("dataSource is nil")
            return cell
        }
        var cellView: UIView? = nil
        if recycleEnabled {
            cellView = cell.contentView.viewWithTag(kSwipeViewCellContentTag)
        } else {
            cell.contentView.viewWithTag(kSwipeViewCellContentTag)?.removeFromSuperview()
        }
        if cellView == nil {
            // set cellView as newly created view
            cellView = dataSource.swipeView(self, viewForIndexPath: indexPath)
            cellView!.tag = kSwipeViewCellContentTag
        }
        indexViewMapper[indexPath.row] = cellView
        
        if recycleEnabled {
            if indexPath.row == currentPage {
                dataSource.swipeView?(self, needUpdateCurrentViewForIndexPath: indexPath, view: cellView!)
            } else {
                dataSource.swipeView?(self, needUpdateViewForIndexPath: indexPath, view: cellView!)
            }
        }
        
        // place view on cell
        if indexPath.row == 0 && count > 1 {
            cellView!.frame.origin.x = 0
        } else {
            // locate content view at center of given cell
            cellView!.frame.origin.x = itemSpace / 2
        }
        cell.contentView.addSubview(cellView!)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !recycleEnabled {
            if let recycledView = cell.contentView.viewWithTag(kSwipeViewCellContentTag) {
                recycledView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension HFSwipeView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if circulating {
            pauseAutoSlide()
        }
        delegate?.swipeView?(self, didSelectItemAtPath: displayIndexUsing(indexPath))
        moveRealPage(indexPath.row, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HFSwipeView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard var itemSize = self.itemSize else {
            loge("item size not provided")
            return .zero
        }
        
        if frame.size.width < itemSize.width {
            loge("item size cannot exceeds parent swipe view")
            return .zero
        }
        
        if circulating {
            itemSize.width += itemSpace
        } else {
            if indexPath.row == 0 || indexPath.row == (count - 1) {
                itemSize.width += itemSpace / 2
            } else {
                itemSize.width += itemSpace
            }
        }
        // locate content view at center of given cell
        collectionView.cellForItem(at: indexPath)?.viewWithTag(kSwipeViewCellContentTag)?.frame.origin.x = itemSpace / 2
        return itemSize
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return contentInsets
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumitemSpaceForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
}

// MARK: - UIScrollViewDelegate
extension HFSwipeView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if circulating {
            pauseAutoSlide()
        }
        delegate?.swipeViewWillBeginDragging?(self)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
//        logd("\(scrollView.contentOffset)")
        
        if !initialized || scrollView.contentSize.width <= 0 {
            // ignore invalid status
            return
        }
        
        if circulating {
            _ = scrollViewFixOffset(scrollView)
            postSync(scrollView.contentOffset, contentSize: scrollView.contentSize)
        }
        
        updateIndexBasedOnContentOffset()
        applyMagnifyCenter()
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        log("[\(self.tag)]")
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        log("[\(self.tag)]: \(scrollView.contentOffset.x), velocity: \(velocity.x), target: \(targetContentOffset.pointee.x)")
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.swipeViewDidEndDragging?(self)
        if !decelerate {
            finishScrolling()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishScrolling()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        log("[\(self.tag)]")
        updateIndexBasedOnContentOffset()
        
        if circulating {
            resumeAutoSlide()
        }
    }
}
