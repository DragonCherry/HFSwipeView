//
//  HFSwipeView.swift
//  Pods
//
//  Created by DragonCherry on 6/30/16.
//
//

import UIKit
import HFUtility


// MARK: - HFSwipeViewDataSource
@objc public protocol HFSwipeViewDataSource: NSObjectProtocol {
    func swipeViewItemCount(swipeView: HFSwipeView) -> Int
    func swipeViewItemSize(swipeView: HFSwipeView) -> CGSize
    func swipeView(swipeView: HFSwipeView, viewForIndexPath indexPath: NSIndexPath) -> UIView
    optional func swipeView(swipeView: HFSwipeView, needUpdateViewForIndexPath indexPath: NSIndexPath, view: UIView)
    optional func swipeView(swipeView: HFSwipeView, needUpdateCurrentViewForIndexPath indexPath: NSIndexPath, view: UIView)
    optional func swipeViewItemDistance(swipeView: HFSwipeView) -> CGFloat
}


// MARK: - HFSwipeViewDelegate
@objc public protocol HFSwipeViewDelegate: NSObjectProtocol {
    optional func swipeView(swipeView: HFSwipeView, didFinishScrollAtIndexPath indexPath: NSIndexPath)
    optional func swipeView(swipeView: HFSwipeView, didSelectItemAtPath indexPath: NSIndexPath)
    optional func swipeView(swipeView: HFSwipeView, didChangeIndexPath indexPath: NSIndexPath)
    optional func swipeViewWillBeginDragging(swipeView: HFSwipeView)
    optional func swipeViewDidEndDragging(swipeView: HFSwipeView)
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
    
    override internal func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if swipeView.autoAlignEnabled {
            return swipeView.centeredOffsetForDefaultOffset(proposedContentOffset, withScrollingVelocity: velocity)
        } else {
            return proposedContentOffset
        }
    }
}


// MARK: - HFSwipeView
public class HFSwipeView: UIView {
    
    // MARK: Private Constants
    private var kSwipeViewCellContentTag: Int!
    private let kSwipeViewCellIdentifier = NSUUID().UUIDString
    private let kPageControlHeight: CGFloat = 20
    private let kPageControlHorizontalPadding: CGFloat = 10
    
    // MARK: Private Variables
    private var initialized: Bool = false
    private var itemSize: CGSize? = nil
    private var itemSpace: CGFloat = 0
    private var pageControl: UIPageControl!
    private var collectionLayout: HFSwipeViewFlowLayout?
    private var indexViewMapper = [Int: UIView]()
    
    // MARK: Loop Control Variables
    private var dummyCount: Int = 0
    private var dummyWidth: CGFloat = 0
    private var realViewCount: Int = 0                          // real item count includes fake views on both side
    private var currentRealPage: Int = -1
    
    // MARK: Sync View
    public var syncView: HFSwipeView?
    
    // MARK: Public Properties
    public var currentPage: Int = -1
    public var collectionView: UICollectionView?
    
    public var collectionBackgroundColor: UIColor? {
        set {
            collectionView!.backgroundView?.backgroundColor = newValue
        }
        get {
            return collectionView!.backgroundView?.backgroundColor
        }
    }
    
    public var circulating: Bool = false
    public var count: Int { // showing count
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
    
    public var autoAlignEnabled: Bool = false
    
    /**
     if set this true, "needUpdateViewForIndexPath" will never called and always use view returned by "viewForIndexPath" instead.
     */
    public var recycleEnabled: Bool = true
    
    public weak var dataSource: HFSwipeViewDataSource? = nil
    public weak var delegate: HFSwipeViewDelegate? = nil
    
    public var pageControlHidden: Bool {
        set(hidden) {
            pageControl.hidden = hidden
        }
        get {
            return pageControl.hidden
        }
    }
    public var currentPageIndicatorTintColor: UIColor? {
        set(color) {
            pageControl.currentPageIndicatorTintColor = color
        }
        get {
            return pageControl.currentPageIndicatorTintColor
        }
    }
    public var pageIndicatorTintColor: UIColor? {
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
    
    private func commonInit() {
        kSwipeViewCellContentTag = self.hash
        loadViews()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }
    
    // MARK: Load & Layout
    private func loadViews() {
        
        self.backgroundColor = UIColor.clearColor()
        
        // collection layout
        let flowLayout = HFSwipeViewFlowLayout(self)
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionLayout = flowLayout
        
        // collection
        let view = UICollectionView(frame: CGRectMake(0, 0, self.width, self.height), collectionViewLayout: self.collectionLayout!)
        view.backgroundColor = UIColor.clearColor()
        view.dataSource = self
        view.delegate = self
        view.bounces = true
        view.registerClass(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: kSwipeViewCellIdentifier)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView = view
        addSubview(collectionView!)
        
        // page control
        pageControl = UIPageControl()
        addSubview(pageControl)
    }
    
    private func prepareForInteraction() {
        initialized = true
        collectionView!.userInteractionEnabled = true
    }
    
    private func calculate() -> Bool {
        
        // retrieve item distance
        self.itemSpace = cgfloat(self.dataSource?.swipeViewItemDistance?(self), defaultValue: 0)
        log("successfully set itemSpace: \(itemSpace)")
        
        // retrieve item size
        self.itemSize = self.dataSource?.swipeViewItemSize(self)
        guard let itemSize = self.itemSize else {
            loge("item size not provided")
            return false
        }
        if itemSize == CGSizeZero {
            loge("item size error: CGSizeZero")
            return false
        } else {
            log("itemSize is \(itemSize)")
        }
        
        // retrieve item count
        let itemCount = integer(self.dataSource?.swipeViewItemCount(self), defaultValue: 0)
        
        // pixel correction
        let neededSpace = (itemSize.width + itemSpace) * CGFloat(itemCount) - (circulating ? 0 : itemSpace)
        if self.width > neededSpace {
            // if given width is wider than needed space
            if itemCount > 0 {
                itemSpace = (self.width - (itemSize.width * CGFloat(itemCount))) / CGFloat(itemCount - 1)
                if circulating {
                    circulating = false
                    dummyWidth = 0
                    dummyCount = 0
                    logw("successfully fixed itemSpace: \(itemSpace)")
                    logw("circulating cancelled as given width(\(self.width)) is wider than needed space(\(neededSpace)).")
                }
            }
        }
        
        if circulating {
            dummyCount = itemCount
            if dummyCount >= 1 {
                dummyWidth = CGFloat(dummyCount) * (itemSize.width + itemSpace)
                log("successfully set dummyCount: \(dummyCount), dummyWidth: \(dummyWidth)")
            }
            
            realViewCount = itemCount > 0 ? itemCount + dummyCount * 2 : 0
            log("successfully set realViewCount: \(realViewCount)")
            
        } else {
            realViewCount = itemCount
        }
        
        var contentSize = CGSize(width: 0, height: itemSize.height)
        if circulating {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2))
        } else {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2) - itemSpace)
        }
        collectionLayout!.estimatedItemSize = itemSize
        collectionLayout!.itemSize = itemSize
        collectionView!.contentSize = contentSize
        log("successfully set content size: \(self.collectionView!.contentSize)")
        
        return true
    }
}



// MARK: - Public APIs
extension HFSwipeView {
    
    public func layoutViews() {
        
        log("\(#function)")
        
        initialized = false
        
        // calculate for view presentation
        if calculate() {
            if let itemSize = self.itemSize {
                collectionView!.size = CGSizeMake(self.width, itemSize.height)
            }
        }
        
        // page control
        self.pageControl.frame = CGRectMake(
            kPageControlHorizontalPadding,
            self.height - kPageControlHeight,
            self.width - 2 * kPageControlHorizontalPadding,
            kPageControlHeight)
        
        // resize page control to match width for swipe view
        let neededWidthForPages = pageControl.sizeForNumberOfPages(count).width
        let ratio = self.pageControl.width / neededWidthForPages
        if ratio < 1 {
            pageControl.transform = CGAffineTransformMakeScale(ratio, ratio)
        }
        pageControl.numberOfPages = count
        
        if count > 0 {
            if currentPage < 0 {
                currentPage = 0
                currentRealPage = dummyCount
            }
            collectionView!.reloadSections(NSIndexSet(index: 0))
            let offset = centeredOffsetForIndex(NSIndexPath(forItem: currentRealPage, inSection: 0))
            collectionView!.setContentOffset(offset, animated: false)
        }
        prepareForInteraction()
    }
    
    public func movePage(page: Int, animated: Bool) {
        
        if page == currentPage {
            log("movePage received same page(\(page)) == currentPage(\(currentPage))")
            autoAlign(collectionView!, indexPath: NSIndexPath(forItem: currentRealPage, inSection: 0))
            return
        }
        let showingIndex = NSIndexPath(forItem: page, inSection: 0)
        let realIndex = closestIndexTo(showingIndex)
        moveRealPage(realIndex.row, animated: animated)
    }
    
    public func deselectItemAtPath(indexPath: NSIndexPath, animated: Bool) {
        self.collectionView?.deselectItemAtIndexPath(indexPath, animated: animated)
    }
}



// MARK: - Private Methods
extension HFSwipeView {
    
    private func moveRealPage(realPage: Int, animated: Bool) {
        if realPage == currentRealPage {
            log("moveRealPage received same page(\(realPage)) == currentPage(\(currentRealPage))")
            return
        }
        log("\(#function)[\(self.tag)]: \(realPage)")
        let realIndex = NSIndexPath(forItem: realPage, inSection: 0)
        let offset = centeredOffsetForIndex(realIndex)
        collectionView!.setContentOffset(offset, animated: animated)
    }
    
    private func closestIndexTo(showingIndex: NSIndexPath) -> NSIndexPath {
        
        let from = currentRealPage
        let dest = showingIndex.row
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
        return NSIndexPath(forItem: minIdx, inSection: 0)
    }
    
    private func centerOffset() -> CGPoint {
        var center = self.collectionView!.contentOffset
        center.x += self.width / 2
        return center
    }
    
    private func centeredOffsetForIndex(indexPath: NSIndexPath) -> CGPoint {
        var newX: CGFloat = 0
        if circulating {
            let cellWidth = itemSpace + cgfloat(itemSize?.width)
            newX += cellWidth * cgfloat(indexPath.row)
            newX -= (self.width - cellWidth) / 2
        } else {
            let cellSpace = (itemSpace + cgfloat(itemSize?.width)) * cgfloat(indexPath.row)
            newX = cellSpace - (self.width - cgfloat(itemSize?.width)) / 2
            
            if newX < 0 {
                // while bouncing on left
                newX = 0
            }
            let rightPivot = collectionView!.contentSize.width - self.width
            if newX > rightPivot {
                // while bouncing on right
                newX = rightPivot
            }
        }
        
        // corrected index
        let centeredOffset = CGPoint(x: newX, y: collectionView!.y)
        return centeredOffset
    }
    
    private func centeredOffsetForDefaultOffset(proposedOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        // corrected index
        guard let proposedIndexPath = indexPathForItemAtPoint(proposedOffset) else {
            loge("nearestIndexPath is nil")
            return CGPointZero
        }
        
        if !circulating && proposedOffset.x == 0 {
            // when bouncing on left
            return proposedOffset
        } else {
            let centeredOffset = centeredOffsetForIndex(proposedIndexPath)
            let centeredIndexPath = indexPathForItemAtPoint(centeredOffset)
            let currentIndex = integer(indexPathForItemAtPoint(CGPointMake(collectionView!.contentOffset.x, 0))?.row)
            if integer(centeredIndexPath?.row) == currentIndex {
                if velocity.x < 0 {
                    return centeredOffsetForIndex(NSIndexPath(forItem: currentIndex - 1, inSection: 0))
                } else if velocity.x > 0 {
                    return centeredOffsetForIndex(NSIndexPath(forItem: currentIndex + 1, inSection: 0))
                } else {
                    return proposedOffset
                }
            } else {
                return centeredOffset
            }
        }
    }
    
    private func indexPathForItemAtPoint(offset: CGPoint) -> NSIndexPath? {
        
        let rightEdge = collectionView!.contentOffset.x + collectionView!.width
        var index: NSIndexPath? = nil
        
        if offset.x < 0 {
            // left edge
            index = NSIndexPath(forRow: 0, inSection: 0)
        } else if rightEdge > collectionView!.contentSize.width {
            // right edge
            index = NSIndexPath(forRow: count - 1, inSection: 0)
        } else {
            // between both side
            index = collectionView!.indexPathForItemAtPoint(centerOffset())
        }
        //        log("size = \(collectionView!.contentSize), offset: \(collectionView!.contentOffset), index: \(index?.row)")
        return index
    }
    
    private func showingIndexUsing(realIndex: NSIndexPath) -> NSIndexPath {
        if circulating {
            var showingIndex = 0
            if realIndex.row < dummyCount {
                showingIndex = realIndex.row - dummyCount + count
            } else if realIndex.row < count + dummyCount {
                showingIndex = realIndex.row - dummyCount
            } else {
                showingIndex = realIndex.row - count - dummyCount
            }
            //            log("\(#function)[\(self.tag)]: \(realIndex.row) -> \(showingIndex)")
            return NSIndexPath(forItem: showingIndex, inSection: 0)
        } else {
            return NSIndexPath(forItem: realIndex.row, inSection: 0)
        }
    }
    
    private func realIndexUsing(showingIndex: NSIndexPath) -> NSIndexPath {
        if !circulating {
            return showingIndex
        }
        var index: Int = 0
        if 0 <= showingIndex.row && showingIndex.row < count {
            index = showingIndex.row + dummyCount
        }
        log("\(#function)[\(self.tag)]: \(showingIndex.row) -> \(index)")
        return NSIndexPath(forItem: index, inSection: 0)
    }
    
    private func realIndexesUsing(showingIndex: NSIndexPath) -> [NSIndexPath] {
        if !circulating {
            return [showingIndex]
        }
        var realIndexes = [NSIndexPath]()
        
        let cut = count - dummyCount
        
        // index on dummy(head) area
        if showingIndex.row - cut >= 0 {
            realIndexes.append(NSIndexPath(forItem: showingIndex.row - cut, inSection: 0))
        }
        // index on center area
        realIndexes.append(NSIndexPath(forItem: dummyCount + showingIndex.row, inSection: 0))
        
        // index on dummy(tail) area
        if dummyCount + count + showingIndex.row < realViewCount {
            realIndexes.append(NSIndexPath(forItem: dummyCount + count + showingIndex.row, inSection: 0))
        }
        
        return realIndexes
    }
    
    private func postSync(contentOffset: CGPoint, contentSize: CGSize) {
        if let syncView = self.syncView {
            //            log("\(#function)[\(self.tag)]")
            syncView.notifiedSync(self)
        }
    }
    
    private func notifiedSync(poster: HFSwipeView) {
        //        log("\(#function)[\(self.tag)]")
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
        let ratio = (posterOffset.x + (poster.width - posterItemSize.width) / 2) / posterSize.width
        var newOffset = CGPoint(x: receiverSize.width * ratio - (self.width - receiverItemSize.width) / 2, y: receiverOffset.y)
        setContentOffsetWithoutCallingDelegate(newOffset)
        updateIndex()
    }
    
    private func setContentOffsetWithoutCallingDelegate(offset: CGPoint) {
        collectionView!.delegate = nil
        collectionView!.contentOffset = offset
        collectionView!.delegate = self
    }
    
    private func updateIndex() {
        
        guard let indexPath = indexPathForItemAtPoint(collectionView!.contentOffset) else {
            logw("indexPathForItemAtPoint returned nil.")
            return
        }
        
        let showingIndex = showingIndexUsing(indexPath)
        let oldPage = currentPage
        
        currentPage = showingIndex.row
        currentRealPage = indexPath.row
        
        if oldPage != currentPage {
            pageControl.currentPage = showingIndex.row
            delegate?.swipeView?(self, didChangeIndexPath: showingIndex)
            if circulating {
                if let view = indexViewMapper[currentPage] {
                    dataSource?.swipeView?(self, needUpdateCurrentViewForIndexPath: showingIndex, view: view)
                } else {
                    loge("Failed to retrieve changed view from indexViewMapper for indexPath: \(indexPath.row)")
                }
            }
            log("\(#function)[\(self.tag)]: \(currentPage)/\(count - 1) - \(currentRealPage)/\(realViewCount - 1)")
        }
    }
    
    private func autoAlign(scrollView: UIScrollView, indexPath: NSIndexPath) {
        if autoAlignEnabled {
            if !circulating {
                let offset = scrollView.contentOffset
                if offset.x > 0 && offset.x < scrollView.contentSize.width - self.width {
                    collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
                }
            } else {
                collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
            }
        }
        log("\(#function)[\(self.tag)]: real -> \(indexPath.row)")
    }
    
    private func scrollViewFixOffset(scrollView: UIScrollView) -> Bool {
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


// MARK: - UICollectionViewDataSource
extension HFSwipeView: UICollectionViewDataSource {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        log("\(#function): \(realViewCount)")
        return realViewCount
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if circulating {
            return cellForItemInCirculationMode(collectionView, indexPath: indexPath)
        } else {
            return cellForItemInNormalMode(collectionView, indexPath: indexPath)
        }
    }
    
    private func cellForItemInCirculationMode(collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(kSwipeViewCellIdentifier, forIndexPath: indexPath)
        guard let dataSource = self.dataSource else {
            loge("dataSource is nil")
            return cell
        }
        
        let showingIndex: NSIndexPath = showingIndexUsing(indexPath)
        var cellView: UIView? = nil
        
        if recycleEnabled {
            // user-created content view may exists while recycling is enabled
            cellView = cell.contentView.viewWithTag(kSwipeViewCellContentTag)
        }
        if cellView == nil {
            // set cellView as newly created view
            cellView = dataSource.swipeView(self, viewForIndexPath: showingIndex)
            cellView!.tag = kSwipeViewCellContentTag
        }
        indexViewMapper[showingIndex.row] = cellView
        
        if recycleEnabled {
            dataSource.swipeView?(self, needUpdateViewForIndexPath: showingIndex, view: cellView!)
        }
        
        if showingIndex.row == currentPage {
            dataSource.swipeView?(self, needUpdateCurrentViewForIndexPath: showingIndex, view: cellView!)
        }
        
        // locate content view at center of given cell
        cellView!.frame.origin.x = itemSpace / 2
        cell.contentView.addSubview(cellView!)
        return cell
    }
    
    private func cellForItemInNormalMode(collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(kSwipeViewCellIdentifier, forIndexPath: indexPath)
        guard let dataSource = self.dataSource else {
            loge("dataSource is nil")
            return cell
        }
        
        var cellView: UIView? = nil
        
        if recycleEnabled {
            // user-created content view may exists while recycling is enabled
            cellView = cell.contentView.viewWithTag(kSwipeViewCellContentTag)
        }
        if cellView == nil {
            // set cellView as newly created view
            cellView = dataSource.swipeView(self, viewForIndexPath: indexPath)
            cellView!.tag = kSwipeViewCellContentTag
        }
        
        if recycleEnabled {
            dataSource.swipeView?(self, needUpdateViewForIndexPath: indexPath, view: cellView!)
        }
        
        if indexPath.row == currentPage {
            dataSource.swipeView?(self, needUpdateCurrentViewForIndexPath: indexPath, view: cellView!)
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
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if !recycleEnabled {
            if let recycledView = cell.contentView.viewWithTag(kSwipeViewCellContentTag) {
                recycledView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension HFSwipeView: UICollectionViewDelegate {
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.swipeView?(self, didSelectItemAtPath: showingIndexUsing(indexPath))
        moveRealPage(indexPath.row, animated: true)
        updateIndex()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HFSwipeView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        guard var itemSize = self.itemSize else {
            loge("item size not provided")
            return CGSizeZero
        }
        
        if self.width < itemSize.width {
            loge("item size cannot exceeds parent swipe view")
            return CGSizeZero
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
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumitemSpaceForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeZero
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeZero
    }
}

// MARK: - UIScrollViewDelegate
extension HFSwipeView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        delegate?.swipeViewWillBeginDragging?(self)
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if !initialized || scrollView.contentSize.width <= 0 {
            // ignore invalid status
            return
        }
        
        if circulating {
            //            log("\(#function)[\(self.tag)]")
            scrollViewFixOffset(scrollView)
            postSync(scrollView.contentOffset, contentSize: scrollView.contentSize)
        }
        
        updateIndex()
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        log("\(#function)[\(self.tag)]")
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        log("\(#function)[\(self.tag)]: \(scrollView.contentOffset.x), velocity: \(velocity.x), target: \(targetContentOffset.memory.x)")
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.swipeViewDidEndDragging?(self)
        if !decelerate {
            finishScrolling()
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        finishScrolling()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        log("\(#function)[\(self.tag)]")
        updateIndex()
    }
    
    private func finishScrolling() {
        
        guard let indexPath = indexPathForItemAtPoint(collectionView!.contentOffset) else {
            return
        }
        log("\(#function)[\(self.tag)]: real -> \(indexPath.row)")
        
        let showingIndex = showingIndexUsing(indexPath)
        delegate?.swipeView?(self, didFinishScrollAtIndexPath: showingIndex)
        
        if circulating {
            if !scrollViewFixOffset(collectionView!) {
                autoAlign(collectionView!, indexPath: indexPath)
            }
        } else {
            autoAlign(collectionView!, indexPath: indexPath)
        }
    }
}