//
//  HFSwipeView+Utility.swift
//  Pods
//
//  Created by DragonCherry on 01/03/2017.
//
//

import UIKit
import TinyLog

// MARK: Common Utilities
internal func integer(_ object: Any?, defaultValue: Int = 0) -> Int {
    if let number = object as? NSNumber {
        return number.intValue
    } else {
        return defaultValue
    }
}
internal func cgfloat(_ object: Any?, defaultValue: CGFloat = 0) -> CGFloat {
    if let number = object as? NSNumber {
        return CGFloat(number.floatValue)
    } else {
        return defaultValue
    }
}

// MARK: - RTL Related Utilities
extension HFSwipeView {
    internal func flippedX(_ x: CGFloat) -> CGFloat {
        if isRtl {
            return collectionView.contentSize.width - frame.size.width - x
        }
        return x
    }
}

extension HFSwipeView {
    internal func addDebugInfo(view: UIView, realIndex: Int, dispIndex: Int) {
        guard isDebug else { return }
        
        var realIndexLabel: UILabel!
        var dispIndexLabel: UILabel!
        
        if let label = view.viewWithTag(0x5000) as? UILabel {
            realIndexLabel = label
        } else {
            realIndexLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 50, height: 20))
            realIndexLabel.textColor = .black
            realIndexLabel.font = .systemFont(ofSize: 8)
            realIndexLabel.tag = 0x5000
            view.addSubview(realIndexLabel)
        }
        if let label = view.viewWithTag(0x5001) as? UILabel {
            dispIndexLabel = label
        } else {
            dispIndexLabel = UILabel(frame: CGRect(x: 5, y: 25, width: 50, height: 20))
            dispIndexLabel.textColor = .black
            dispIndexLabel.font = .systemFont(ofSize: 8)
            dispIndexLabel.tag = 0x5001
            view.addSubview(dispIndexLabel)
        }
        
        realIndexLabel.text = "\(realIndex)/\(realViewCount)"
        dispIndexLabel.text = "\(dispIndex)/\(count)"
    }
}
