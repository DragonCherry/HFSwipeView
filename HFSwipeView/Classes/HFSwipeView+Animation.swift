//
//  HFSwipeView+Animation.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: - Magnify
extension HFSwipeView {
    internal func applyMagnifyCenter(forCell cell: UICollectionViewCell) {
        if !magnifyCenter {
            return
        }
        
        let left = self.collectionView.contentOffset.x + itemSize!.width / 2
        let right = self.collectionView.contentOffset.x + frame.size.width - itemSize!.width / 2
        let center = centerOffset.x
        let ratio = centerRatio(left, right: right, center: center, cell: cell)
        
        magnifyCell(cell, forRatio: ratio)
    }
    
    internal func applyMagnifyCenter() {
        if !magnifyCenter {
            return
        }
        let cells = collectionView.visibleCells
        
        let left = self.collectionView.contentOffset.x + itemSize!.width / 2
        let right = self.collectionView.contentOffset.x + frame.size.width - itemSize!.width / 2
        let center = centerOffset.x
        
        for cell in cells {
            let ratio = centerRatio(left, right: right, center: center, cell: cell)
            magnifyCell(cell, forRatio: ratio)
        }
    }
    
    internal func magnifyCell(_ cell: UICollectionViewCell, forRatio ratio: CGFloat) {
        
        if let cellView = cell.contentView.viewWithTag(kSwipeViewCellContentTag) {
            var bonusRatio: CGFloat = preferredMagnifyBonusRatio
            let cellWidth = itemSize!.width + itemSpace
            if itemSize!.width * bonusRatio > cellWidth {
                bonusRatio = cellWidth / itemSize!.width
            }
            
            // resizeRatio by center-ratio
            if ratio >= 0 {
                bonusRatio = (ratio - 1) * (bonusRatio - 1) * -1 + 1
            } else {
                bonusRatio = (ratio + 1) * (bonusRatio - 1) + 1
            }
            
            let viewWidth = itemSize!.width * bonusRatio
            cellView.transform = CGAffineTransform(scaleX: bonusRatio, y: bonusRatio)
            let space = (cellWidth - viewWidth) / 2
            cellView.frame.origin = CGPoint(x: space, y: cellView.frame.origin.y)
        }
    }
    
    internal func centerRatio(_ left: CGFloat, right: CGFloat, center: CGFloat, cell: UICollectionViewCell) -> CGFloat {
        
        var ratio: CGFloat = 0
        let divider = center - left
        if cell.center.x < center {
            ratio = (center - cell.center.x) / divider * -1
            if ratio < -1 {
                ratio = -1
            }
        } else if cell.center.x > center {
            ratio = (cell.center.x - center) / divider
            if ratio > 1 {
                ratio = 1
            }
        } else {
            ratio = 0
        }
        
        return ratio
    }
}
