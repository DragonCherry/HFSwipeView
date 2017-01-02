//
//  HFSwipeView.swift
//  Pods
//
//  Created by DragonCherry on 6/30/16.
//
//

import UIKit

// MARK: Common Utilities
internal func printDetail(_ message: String) {
    #if DEBUG
        print("(\(String(#file)):\(#line)) \(message)")
    #endif
}

internal func log(_ message: String?) {
    #if DEBUG
        if let message = message {
            print(message)
        } else {
            printDetail("nil message")
        }
    #endif
}

internal func loge(_ message: String?) { printDetail("[Error]: \(message)") }
internal func loge(_ error: Error?) { printDetail("[Error]: \(error)") }
internal func logw(_ message: String?) { printDetail("[Warning]: \(message)") }
internal func integer(_ object: AnyObject?, defaultValue: Int = 0) -> Int {
    if let number = object as? NSNumber {
        return number.intValue
    } else {
        return defaultValue
    }
}
internal func cgfloat(_ object: AnyObject?, defaultValue: CGFloat = 0) -> CGFloat {
    if let number = object as? NSNumber {
        return CGFloat(number.floatValue)
    } else {
        return defaultValue
    }
}


// MARK: - HFSwipeViewDataSource
@objc public protocol HFSwipeViewDataSource: NSObjectProtocol {
    func swipeViewItemCount(_ swipeView: HFSwipeView) -> Int
    func swipeViewItemSize(_ swipeView: HFSwipeView) -> CGSize
    func swipeView(_ swipeView: HFSwipeView, viewForIndexPath indexPath: IndexPath) -> UIView
    @objc optional func swipeView(_ swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: IndexPath, view: UIView)
    @objc optional func swipeView(_ swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: IndexPath, view: UIView)
    /// This delegate method will invoked only in circulation mode.
    @objc optional func swipeViewContentInsets(_ swipeView: HFSwipeView) -> UIEdgeInsets
    @objc optional func swipeViewItemDistance(_ swipeView: HFSwipeView) -> CGFloat
}


// MARK: - HFSwipeViewDelegate
@objc public protocol HFSwipeViewDelegate: NSObjectProtocol {
    @objc optional func swipeView(_ swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: IndexPath)
    @objc optional func swipeView(_ swipeView: HFSwipeView, didSelectItemAtPath indexPath: IndexPath)
    @objc optional func swipeView(_ swipeView: HFSwipeView, didChangeIndexPath indexPath: IndexPath)
    @objc optional func swipeViewWillBeginDragging(_ swipeView: HFSwipeView)
    @objc optional func swipeViewDidEndDragging(_ swipeView: HFSwipeView)
}


// MARK: - HFSwipeViewFlowLayout
class HFSwipeViewFlowLayout: UICollectionViewFlowLayout {
    
    weak var swipeView: HFSwipeView!
    
    init(_ swipeView: HFSwipeView) {
        super.init()
        self.swipeView = swipeView
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override internal func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if swipeView.autoAlignEnabled {
            return swipeView.centeredOffsetForDefaultOffset(proposedContentOffset, withScrollingVelocity: velocity)
        } else {
            return proposedContentOffset
        }
    }
}


// MARK: - HFSwipeView
open class HFSwipeView: UIView {
    
    // MARK: Private Constants
    fileprivate var kSwipeViewCellContentTag: Int!
    fileprivate let kSwipeViewCellIdentifier = UUID().uuidString
    fileprivate let kPageControlHeight: CGFloat = 20
    fileprivate let kPageControlHorizontalPadding: CGFloat = 10
    
    // MARK: Private Variables
    fileprivate var initialized: Bool = false
    fileprivate var itemSize: CGSize? = nil
    fileprivate var itemSpace: CGFloat = 0
    fileprivate var pageControl: UIPageControl!
    fileprivate var collectionLayout: HFSwipeViewFlowLayout?
    fileprivate var indexViewMapper = [Int: UIView]()
    fileprivate var contentInsets: UIEdgeInsets {
        if var insets = dataSource?.swipeViewContentInsets?(self) {
            if insets.top != 0 {
                logw("Changing UIEdgeInsets.top for HFSwipeView is not supported yet, consider a container view instead.")
                insets.top = 0
            }
            if insets.bottom != 0 {
                logw("Changing UIEdgeInsets.bottom for HFSwipeView is not supported yet, consider a container view instead.")
                insets.bottom = 0
            }
            return insets
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    // MARK: Loop Control Variables
    fileprivate var dummyCount: Int = 0
    fileprivate var dummyWidth: CGFloat = 0
    fileprivate var realViewCount: Int = 0                          // real item count includes fake views on both side
    fileprivate var currentRealPage: Int = -1
    
    // MARK: Auto Slide
    fileprivate var autoSlideInterval: TimeInterval = -1
    fileprivate var autoSlideIntervalBackupForLaterUse: TimeInterval = -1
    fileprivate var autoSlideTimer: Timer?
    
    // MARK: Sync View
    open var syncView: HFSwipeView?
    
    // MARK: Public Properties
    open var currentPage: Int = -1
    open var collectionView: UICollectionView?
    
    open var collectionBackgroundColor: UIColor? {
        set {
            collectionView!.backgroundView?.backgroundColor = newValue
        }
        get {
            return collectionView!.backgroundView?.backgroundColor
        }
    }
    
    open var circulating: Bool = false
    open var count: Int { // showing count
        if circulating {
            if realViewCount < 0 {
                loge("cannot use property \"count\" before set HFSwipeView.realViewCount")
                return -1
            }
            if realViewCount > 0 {
                return realViewCount - 2 * dummyCount
            } else {
                return 0
            }
        } else {
            return realViewCount
        }
    }
    
    open var magnifyCenter: Bool = false
    open var preferredMagnifyBonusRatio: CGFloat = 1
    
    open var autoAlignEnabled: Bool = false
    
    /**
     if set this true, "needUpdateViewForIndexPath" will never called and always use view returned by "viewForIndexPath" instead.
     */
    open var recycleEnabled: Bool = true
    
    open weak var dataSource: HFSwipeViewDataSource? = nil
    open weak var delegate: HFSwipeViewDelegate? = nil
    
    open var pageControlHidden: Bool {
        set(hidden) {
            pageControl.isHidden = hidden
        }
        get {
            return pageControl.isHidden
        }
    }
    open var currentPageIndicatorTintColor: UIColor? {
        set(color) {
            pageControl.currentPageIndicatorTintColor = color
        }
        get {
            return pageControl.currentPageIndicatorTintColor
        }
    }
    open var pageIndicatorTintColor: UIColor? {
        set(color) {
            pageControl.pageIndicatorTintColor = color
        }
        get {
            return pageControl.pageIndicatorTintColor
        }
    }
    
    // MARK: Lifecycle
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    fileprivate func commonInit() {
        kSwipeViewCellContentTag = self.hash
        loadViews()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }
    
    // MARK: Load & Layout
    fileprivate func loadViews() {
        
        self.backgroundColor = UIColor.clear
        
        // collection layout
        let flowLayout = HFSwipeViewFlowLayout(self)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionLayout = flowLayout
        
        // collection
        let view = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), collectionViewLayout: self.collectionLayout!)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.bounces = true
        view.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: kSwipeViewCellIdentifier)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView = view
        addSubview(collectionView!)
        
        // page control
        pageControl = UIPageControl()
        addSubview(pageControl)
    }
    
    fileprivate func prepareForInteraction() {
        applyMagnifyCenter()
        initialized = true
        collectionView!.isUserInteractionEnabled = true
    }
    
    fileprivate func calculate() -> Bool {
        
        // retrieve item distance
        itemSpace = cgfloat(dataSource?.swipeViewItemDistance?(self) as AnyObject?, defaultValue: 0)
        log("successfully set itemSpace: \(itemSpace)")
        
        // retrieve item size
        itemSize = dataSource?.swipeViewItemSize(self)
        guard let itemSize = itemSize else {
            loge("item size not provided")
            return false
        }
        if itemSize == CGSize.zero {
            loge("item size error: CGSizeZero")
            return false
        } else {
            log("itemSize is \(itemSize)")
        }
        
        // retrieve item count
        let itemCount = integer(self.dataSource?.swipeViewItemCount(self) as AnyObject?, defaultValue: 0)
        
        // pixel correction
        if circulating {
            let neededSpace = (itemSize.width + itemSpace) * CGFloat(itemCount) - (circulating ? 0 : itemSpace)
            if frame.size.width > neededSpace {
                // if given width is wider than needed space
                if itemCount > 0 {
                    itemSpace = (frame.size.width - (itemSize.width * CGFloat(itemCount))) / CGFloat(itemCount)
                    logw("successfully fixed itemSpace: \(itemSpace)")
                }
            }
            dummyCount = itemCount
            if dummyCount >= 1 {
                dummyWidth = CGFloat(dummyCount) * (itemSize.width + itemSpace)
                log("successfully set dummyCount: \(dummyCount), dummyWidth: \(dummyWidth)")
            }
            
            realViewCount = itemCount > 0 ? itemCount + dummyCount * 2 : 0
            log("successfully set realViewCount: \(realViewCount)")
            
        } else {
            collectionView!.alwaysBounceHorizontal = true
            realViewCount = itemCount
        }
        
        var contentSize = CGSize(width: 0, height: itemSize.height)
        if circulating {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2))
        } else {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2) - itemSpace)
        }
        collectionLayout!.itemSize = itemSize
        collectionView!.contentSize = contentSize
        collectionView!.reloadData()
        log("successfully set content size: \(collectionView!.contentSize)")
        
        return true
    }
}



// MARK: - Public APIs
extension HFSwipeView {
    
    public func layoutViews() {
        
        log("\(type(of: self)) - \(#function)")
        
        initialized = false
        
        // force recycle mode in circulation mode
        recycleEnabled = circulating ? true : recycleEnabled
        
        // calculate for view presentation
        if calculate() {
            if let itemSize = self.itemSize {
                collectionView!.frame.size = CGSize(width: frame.size.width, height: itemSize.height)
            }
        }
        
        // page control
        self.pageControl.frame = CGRect(
            x: kPageControlHorizontalPadding,
            y: frame.size.height - kPageControlHeight,
            width: frame.size.width - 2 * kPageControlHorizontalPadding,
            height: kPageControlHeight)
        
        // resize page control to match width for swipe view
        let neededWidthForPages = pageControl.size(forNumberOfPages: count).width
        let ratio = pageControl.frame.size.width / neededWidthForPages
        if ratio < 1 {
            pageControl.transform = CGAffineTransform(scaleX: ratio, y: ratio)
        }
        pageControl.numberOfPages = count
        
        if count > 0 {
            if circulating {
                if currentRealPage < dummyCount {
                    currentRealPage = dummyCount
                } else if currentRealPage > count + dummyCount {
                    currentRealPage = dummyCount
                }
                let offset = centeredOffsetForIndex(IndexPath(item: currentRealPage < 0 ? dummyCount : currentRealPage, section: 0))
                collectionView!.setContentOffset(offset, animated: false)
            } else {
                currentPage = 0
                currentRealPage = 0
                let offset = centeredOffsetForIndex(IndexPath(item: currentRealPage < 0 ? 0 : currentRealPage, section: 0))
                collectionView!.setContentOffset(offset, animated: false)
            }
        }
        prepareForInteraction()
    }
    
    public func movePage(_ page: Int, animated: Bool) {
        
        if page == currentPage {
            log("movePage received same page(\(page)) == currentPage(\(currentPage))")
            autoAlign(collectionView!, indexPath: IndexPath(item: currentRealPage, section: 0))
            return
        }
        let displayIndex = IndexPath(item: page, section: 0)
        let realIndex = closestIndexTo(displayIndex)
        moveRealPage(realIndex.row, animated: animated)
    }
    
    public func deselectItemAtPath(_ indexPath: IndexPath, animated: Bool) {
        self.collectionView?.deselectItem(at: indexPath, animated: animated)
    }
}



// MARK: - Public APIs: Auto Slide
extension HFSwipeView {
    /// zero or minus interval disables auto slide.
    public func startAutoSlideForTimeInterval(_ interval: TimeInterval) {
        log("\(#function)")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if interval > 0 {
            stopAutoSlide()
            autoSlideInterval = interval
            autoSlideTimer = Timer.scheduledTimer(
                timeInterval: interval,
                target: self,
                selector: #selector(HFSwipeView.autoSlideCallback(_:)),
                userInfo: nil,
                repeats: true)
        }
    }
    
    public func pauseAutoSlide() {
        log("\(#function)")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if autoSlideInterval > 0 {
            autoSlideIntervalBackupForLaterUse = autoSlideInterval
        }
        autoSlideInterval = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    public func resumeAutoSlide() {
        log("\(#function)")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        if autoSlideIntervalBackupForLaterUse > 0 {
            startAutoSlideForTimeInterval(autoSlideIntervalBackupForLaterUse)
        }
    }
    
    public func stopAutoSlide() {
        log("\(#function)")
        if !circulating {
            logw("Cannot use auto-slide without circulation mode.")
            return
        }
        autoSlideInterval = -1
        autoSlideIntervalBackupForLaterUse = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    public func autoSlideCallback(_ timer: Timer) {
        DispatchQueue.main.async {
            self.movePage((self.currentPage + 1) % self.count, animated: true)
        }
    }
}



// MARK: - Private Methods: Offset Control
extension HFSwipeView {
    fileprivate func centerOffset() -> CGPoint {
        var center = self.collectionView!.contentOffset
        center.x += frame.size.width / 2
        return center
    }
    
    fileprivate func centeredOffsetForIndex(_ indexPath: IndexPath) -> CGPoint {
        var newX: CGFloat = 0
        if circulating {
            let cellWidth = itemSpace + cgfloat(itemSize?.width as AnyObject?)
            newX += cellWidth * cgfloat(indexPath.row as AnyObject?)
            newX -= (frame.size.width - cellWidth) / 2
        } else {
            let cellWidth = itemSpace + cgfloat(itemSize?.width as AnyObject?)
            let cellSpace = cellWidth * cgfloat(indexPath.row as AnyObject?)
            newX = cellSpace - (frame.size.width - cellWidth) / 2
            if newX < 0 {
                newX = 0
            }
            if newX > collectionView!.contentSize.width - frame.size.width {
                newX = collectionView!.contentSize.width - frame.size.width
            }
        }
        
        // corrected index
        let centeredOffset = CGPoint(x: newX, y: collectionView!.frame.origin.y)
        return centeredOffset
    }
    
    fileprivate func centeredOffsetForDefaultOffset(_ proposedOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
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
            let currentIndex = integer(indexPathForItemAtPoint(CGPoint(x: collectionView!.contentOffset.x, y: 0))?.row as AnyObject?)
            if integer(centeredIndexPath?.row as AnyObject?) == currentIndex {
                if velocity.x < 0 {
                    return centeredOffsetForIndex(IndexPath(item: currentIndex - 1, section: 0))
                } else if velocity.x > 0 {
                    return centeredOffsetForIndex(IndexPath(item: currentIndex + 1, section: 0))
                } else {
                    return proposedOffset
                }
            } else {
                return centeredOffset
            }
        }
    }
    
    fileprivate func setContentOffsetWithoutCallingDelegate(_ offset: CGPoint) {
        collectionView!.delegate = nil
        collectionView!.contentOffset = offset
        collectionView!.delegate = self
    }
    
    fileprivate func updateIndexBasedOnContentOffset() {
        
        if !circulating {
            return
        }
        
        guard let indexPath = indexPathForItemAtPoint(collectionView!.contentOffset) else {
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
            log("\(#function)[\(self.tag)]: \(currentPage)/\(count - 1) - \(currentRealPage)/\(realViewCount - 1)")
        }
    }
    
    fileprivate func scrollViewFixOffset(_ scrollView: UIScrollView) -> Bool {
        let offset = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        if offset.x < dummyWidth {
            let delta = dummyWidth - offset.x
            setContentOffsetWithoutCallingDelegate(CGPoint(x: contentSize.width - dummyWidth - delta, y: 0))
            log("\(#function)[\(self.tag)]: moved to last view, offset: \(scrollView.contentOffset)")
            return true
        } else if offset.x >= contentSize.width - dummyWidth {
            let delta = offset.x - (contentSize.width - dummyWidth)
            setContentOffsetWithoutCallingDelegate(CGPoint(x: self.dummyWidth + delta, y: 0))
            log("\(#function)[\(self.tag)]: moved to first view!, offset: \(scrollView.contentOffset)")
            return true
        }
        return false
    }
}



// MARK: - Private Methods: Index Control
extension HFSwipeView {
    fileprivate func closestIndexTo(_ displayIndex: IndexPath) -> IndexPath {
        
        let from = currentRealPage
        let dest = displayIndex.row
        var minDiff: Int = count + dummyCount * 2
        var minIdx: Int = -1
        var index = count - dummyCount
        
        // traverse header
        for i in 0..<dummyCount {
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
        
        // traverse body
        for i in dummyCount..<(dummyCount + count) {
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
        
        // traverse tail
        for i in (dummyCount + count)..<(count + dummyCount * 2) {
            if dest == index {
                let newDiff = from > i ? from - i : i - from
                if newDiff < minDiff {
                    minDiff = newDiff
                    minIdx = i
                }
            }
            index += 1
        }
        log("\(#function)[\(self.tag)]: from: \(from) to: \(minIdx)")
        return IndexPath(item: minIdx, section: 0)
    }
    
    fileprivate func indexPathForItemAtPoint(_ offset: CGPoint) -> IndexPath? {
        
        let rightEdge = collectionView!.contentOffset.x + collectionView!.frame.size.width
        var index: IndexPath? = nil
        let center = centerOffset()
        
        if offset.x < 0 {
            // left edge
            index = IndexPath(row: 0, section: 0)
        } else if rightEdge > collectionView!.contentSize.width {
            // right edge
            index = IndexPath(row: count - 1, section: 0)
        } else {
            // between both side
            index = collectionView!.indexPathForItem(at: center)
        }
//        log("center = \(center), size = \(collectionView!.contentSize), offset: \(collectionView!.contentOffset), index: \(index?.row)")
        return index
    }
    
    fileprivate func displayIndexUsing(_ realIndex: IndexPath) -> IndexPath {
        if circulating {
            var displayIndex = 0
            if realIndex.row < dummyCount {
                displayIndex = realIndex.row - dummyCount + count
            } else if realIndex.row < count + dummyCount {
                displayIndex = realIndex.row - dummyCount
            } else {
                displayIndex = realIndex.row - count - dummyCount
            }
            //            log("\(#function)[\(self.tag)]: \(realIndex.row) -> \(displayIndex)")
            return IndexPath(item: displayIndex, section: 0)
        } else {
            return IndexPath(item: realIndex.row, section: 0)
        }
    }
    
    fileprivate func realIndexUsing(_ displayIndex: IndexPath) -> IndexPath {
        if !circulating {
            return displayIndex
        }
        var index: Int = 0
        if 0 <= displayIndex.row && displayIndex.row < count {
            index = displayIndex.row + dummyCount
        }
        log("\(#function)[\(self.tag)]: \(displayIndex.row) -> \(index)")
        return IndexPath(item: index, section: 0)
    }
    
    fileprivate func realIndexesUsing(_ displayIndex: IndexPath) -> [IndexPath] {
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
}

// MARK: - Private Methods: Page Control
extension HFSwipeView {
    
    fileprivate func moveRealPage(_ realPage: Int, animated: Bool) {
        if realPage >= 0 && realPage < realViewCount && realPage == currentRealPage {
            log("moveRealPage received same page(\(realPage)) == currentPage(\(currentRealPage))")
            return
        }
        log("\(#function)[\(self.tag)]: \(realPage)")
        
        let realIndex = IndexPath(item: realPage, section: 0)
        
        if autoAlignEnabled {
            let offset = centeredOffsetForIndex(realIndex)
            collectionView!.setContentOffset(offset, animated: animated)
        }
        
        if !circulating {
            updateCurrentView(displayIndexUsing(realIndex))
        }
    }
    
    fileprivate func updateCurrentView(_ displayIndex: IndexPath) {
        currentPage = displayIndex.row
        currentRealPage = displayIndex.row
        if let view = indexViewMapper[currentRealPage] {
            dataSource?.swipeView?(self, needUpdateCurrentViewForIndexPath: displayIndex, view: view)
        } else {
            logw("Failed to retrieve current view from indexViewMapper for indexPath: \(displayIndex.row)")
        }
        
    }
    
    fileprivate func postSync(_ contentOffset: CGPoint, contentSize: CGSize) {
        if let syncView = self.syncView {
            syncView.notifiedSync(self)
        }
    }
    
    fileprivate func notifiedSync(_ poster: HFSwipeView) {
        guard
            let posterItemSize = poster.itemSize,
            let posterOffset = poster.collectionView?.contentOffset,
            let posterSize = poster.collectionView?.contentSize
            else {
                logw("sender HFSwipeView is not ready.")
                return
        }
        guard
            let receiverItemSize = self.itemSize,
            let receiverOffset = self.collectionView?.contentOffset,
            let receiverSize = self.collectionView?.contentSize
            else {
                logw("receiver HFSwipeView is not ready.")
                return
        }
        let ratio = (posterOffset.x + (poster.frame.size.width - posterItemSize.width) / 2) / posterSize.width
        let newOffset = CGPoint(x: receiverSize.width * ratio - (frame.size.width - receiverItemSize.width) / 2, y: receiverOffset.y)
        setContentOffsetWithoutCallingDelegate(newOffset)
        updateIndexBasedOnContentOffset()
    }
    
    fileprivate func autoAlign(_ scrollView: UIScrollView, indexPath: IndexPath) {
        if autoAlignEnabled {
            if !circulating {
                let offset = scrollView.contentOffset
                if offset.x > 0 && offset.x < scrollView.contentSize.width - frame.size.width {
                    collectionView!.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                }
            } else {
                collectionView!.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
        log("\(#function)[\(self.tag)]: real -> \(indexPath.row)")
    }
}


// MARK: - Magnify
extension HFSwipeView {
    fileprivate func applyMagnifyCenter(forCell cell: UICollectionViewCell) {
        if !magnifyCenter {
            return
        }
        
        let left = self.collectionView!.contentOffset.x + itemSize!.width / 2
        let right = self.collectionView!.contentOffset.x + frame.size.width - itemSize!.width / 2
        let center = centerOffset().x
        let ratio = centerRatio(left, right: right, center: center, cell: cell)
        
        magnifyCell(cell, forRatio: ratio)
    }
    
    fileprivate func applyMagnifyCenter() {
        if !magnifyCenter {
            return
        }
        let cells = collectionView!.visibleCells
        var cellsText = ""
        
        let left = self.collectionView!.contentOffset.x + itemSize!.width / 2
        let right = self.collectionView!.contentOffset.x + frame.size.width - itemSize!.width / 2
        let center = centerOffset().x
        
        for cell in cells {
            let ratio = centerRatio(left, right: right, center: center, cell: cell)
            cellsText += "(\(cell.tag):\(ratio)) "
            magnifyCell(cell, forRatio: ratio)
        }
        //        log("\(#function): \(cellsText)")
    }
    
    fileprivate func magnifyCell(_ cell: UICollectionViewCell, forRatio ratio: CGFloat) {
        
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
            //            log("bonusRatio: \(bonusRatio)")
            
            let viewWidth = itemSize!.width * bonusRatio
            cellView.transform = CGAffineTransform(scaleX: bonusRatio, y: bonusRatio)
            let space = (cellWidth - viewWidth) / 2
            cellView.frame.origin = CGPoint(x: space, y: cellView.frame.origin.y)
        }
    }
    
    fileprivate func centerRatio(_ left: CGFloat, right: CGFloat, center: CGFloat, cell: UICollectionViewCell) -> CGFloat {
        
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



// MARK: - UICollectionViewDataSource
extension HFSwipeView: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        log("\(#function): \(realViewCount)")
        return realViewCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if circulating {
            return cellForItemInCirculationMode(collectionView, indexPath: indexPath)
        } else {
            return cellForItemInNormalMode(collectionView, indexPath: indexPath)
        }
    }
    
    fileprivate func cellForItemInCirculationMode(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: kSwipeViewCellIdentifier, for: indexPath)
        guard let dataSource = self.dataSource else {
            loge("dataSource is nil")
            return cell
        }
        
        let displayIndex: IndexPath = displayIndexUsing(indexPath)
        
        var cellView: UIView? = nil
        if recycleEnabled {
            cellView = cell.contentView.viewWithTag(kSwipeViewCellContentTag)
        } else {
            cell.contentView.viewWithTag(kSwipeViewCellContentTag)?.removeFromSuperview()
        }
        if cellView == nil {
            // set cellView as newly created view
            cellView = dataSource.swipeView(self, viewForIndexPath: displayIndex)
            cellView!.tag = kSwipeViewCellContentTag
        }
        indexViewMapper[indexPath.row] = cellView
        
        // locate content view at center of given cell
        cellView!.frame.origin.x = itemSpace / 2
        cell.contentView.addSubview(cellView!)
        
        if magnifyCenter {
            cell.tag = indexPath.row
            applyMagnifyCenter(forCell: cell)
        }
        
        if displayIndex.row == currentPage {
            log("\(#function)[CURRENT][\(displayIndex.row)/\(indexPath.row)]")
            dataSource.swipeView?(self, needUpdateCurrentViewForIndexPath: displayIndex, view: cellView!)
        } else {
            log("\(#function)[NORMAL][\(displayIndex.row)/\(indexPath.row)]")
            dataSource.swipeView?(self, needUpdateViewForIndexPath: displayIndex, view: cellView!)
        }
        return cell
    }
    
    fileprivate func cellForItemInNormalMode(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
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
            return CGSize.zero
        }
        
        if frame.size.width < itemSize.width {
            loge("item size cannot exceeds parent swipe view")
            return CGSize.zero
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
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
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
        
        if !initialized || scrollView.contentSize.width <= 0 {
            // ignore invalid status
            return
        }
        
        if circulating {
            scrollViewFixOffset(scrollView)
            postSync(scrollView.contentOffset, contentSize: scrollView.contentSize)
        }
        
        updateIndexBasedOnContentOffset()
        applyMagnifyCenter()
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        log("\(#function)[\(self.tag)]")
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        log("\(#function)[\(self.tag)]: \(scrollView.contentOffset.x), velocity: \(velocity.x), target: \(targetContentOffset.pointee.x)")
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
        log("\(#function)[\(self.tag)]")
        updateIndexBasedOnContentOffset()
        
        if circulating {
            resumeAutoSlide()
        }
    }
    
    fileprivate func finishScrolling() {
        
        guard let indexPath = indexPathForItemAtPoint(collectionView!.contentOffset) else {
            return
        }
        log("\(#function)[\(self.tag)]: real -> \(indexPath.row)")
        
        let displayIndex = displayIndexUsing(indexPath)
        delegate?.swipeView?(self, didFinishScrollAtIndexPath: displayIndex)
        
        if circulating {
            if !scrollViewFixOffset(collectionView!) {
                autoAlign(collectionView!, indexPath: indexPath)
            }
        } else {
            autoAlign(collectionView!, indexPath: indexPath)
        }
        
        if circulating {
            resumeAutoSlide()
        }
    }
}
