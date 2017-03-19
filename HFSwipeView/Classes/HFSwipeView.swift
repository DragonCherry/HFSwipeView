//
//  HFSwipeView.swift
//  Pods
//
//  Created by DragonCherry on 6/30/16.
//
//

import UIKit
import TinyLog
import PureLayout

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
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if swipeView.autoAlignEnabled {
            return swipeView.centeredOffsetForDefaultOffset(proposedContentOffset, withScrollingVelocity: velocity)
        } else {
            return proposedContentOffset
        }
    }
}


// MARK: - HFSwipeView
open class HFSwipeView: UIView {
    
    // MARK: Debug Mode for Development
    public var isDebug: Bool = false
    
    // MARK: Internal Constants
    internal var kSwipeViewCellContentTag: Int!
    internal let kSwipeViewCellIdentifier = UUID().uuidString
    
    // MARK: Internal Variables
    internal var didSetupConstraints: Bool = false
    internal var isRtl: Bool = false
    internal var initialized: Bool = false
    internal var itemSize: CGSize? = nil
    internal var itemSpace: CGFloat = 0
    internal var indexViewMapper = [Int: UIView]()
    internal var contentInsets: UIEdgeInsets {
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
    internal var dummyCount: Int = 0
    internal var dummyWidth: CGFloat = 0
    internal var realViewCount: Int = 0                          // real item count includes fake views on both side
    internal var currentRealPage: Int = -1
    
    // MARK: Auto Slide
    internal var autoSlideInterval: TimeInterval = -1
    internal var autoSlideIntervalBackupForLaterUse: TimeInterval = -1
    internal var autoSlideTimer: Timer?
    
    // MARK: Sync View
    open var syncView: HFSwipeView?
    
    // MARK: Public Properties
    open var currentPage: Int = -1
    open var pageControlHeight: CGFloat = 20
    open var pageControlInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    // MARK: Views
    open let pageControl: UIPageControl = {
        let view = UIPageControl.newAutoLayout()
        return view
    }()
    
    open lazy var collectionView: UICollectionView = {
        let flowLayout = HFSwipeViewFlowLayout(self)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        view.configureForAutoLayout()
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.bounces = true
        view.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: self.kSwipeViewCellIdentifier)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.decelerationRate = UIScrollViewDecelerationRateFast
        view.backgroundColor = .clear
        return view
    }()
    
    open var collectionBackgroundColor: UIColor? {
        set { collectionView.backgroundView?.backgroundColor = newValue }
        get { return collectionView.backgroundView?.backgroundColor }
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
        set(isHidden) { pageControl.isHidden = isHidden }
        get { return pageControl.isHidden }
    }
    open var currentPageIndicatorTintColor: UIColor? {
        set(color) { pageControl.currentPageIndicatorTintColor = color }
        get { return pageControl.currentPageIndicatorTintColor }
    }
    open var pageIndicatorTintColor: UIColor? {
        set(color) { pageControl.pageIndicatorTintColor = color }
        get { return pageControl.pageIndicatorTintColor }
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
        // generate hash
        kSwipeViewCellContentTag = self.hash
        
        // check RTL
        if let languageCode = NSLocale.current.languageCode {
            isRtl = NSLocale.characterDirection(forLanguage: languageCode) == .rightToLeft
        }
        
        addSubview(collectionView)
        addSubview(pageControl)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            collectionView.autoPinEdgesToSuperviewEdges()
            pageControl.autoPinEdgesToSuperviewEdges(with: pageControlInsets, excludingEdge: .top)
            pageControl.autoSetDimension(.height, toSize: pageControlHeight)
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    override open var bounds: CGRect {
        didSet {
            if oldValue.height != bounds.height || oldValue.width != bounds.width {
                calculate()
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }
    
    fileprivate func prepareForInteraction() {
        applyMagnifyCenter()
        initialized = true
        collectionView.isUserInteractionEnabled = true
    }
    
    @discardableResult fileprivate func calculate() -> Bool {
        
        // retrieve item distance
        itemSpace = cgfloat(dataSource?.swipeViewItemDistance?(self), defaultValue: 0)
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
        let itemCount = integer(self.dataSource?.swipeViewItemCount(self), defaultValue: 0)
        
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
            collectionView.alwaysBounceHorizontal = true
            realViewCount = itemCount
        }
        
        var contentSize = CGSize(width: 0, height: itemSize.height)
        if circulating {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2))
        } else {
            contentSize.width = ceil((itemSize.width + itemSpace) * CGFloat(itemCount + dummyCount * 2) - itemSpace)
        }
        (collectionView.collectionViewLayout as? HFSwipeViewFlowLayout)?.itemSize = itemSize
        setContentSizeWithoutCallingDelegate(contentSize)
        log("successfully set content size: \(collectionView.contentSize)")
        
        return true
    }
}


// MARK: - Internal UI Control
extension HFSwipeView {
    
    private func fitPageControl() {
        // resize page control to match width for swipe view
        let neededWidthForPages = pageControl.size(forNumberOfPages: count).width
        let ratio = pageControl.frame.size.width / neededWidthForPages
        if ratio < 1 {
            pageControl.transform = CGAffineTransform(scaleX: ratio, y: ratio)
        }
        pageControl.numberOfPages = count
    }
    
    fileprivate func layoutViews() {
        
        initialized = false
        
        // force recycle mode in circulation mode
        recycleEnabled = circulating ? true : recycleEnabled
        
        // calculate for view presentation
        calculate()
        
        // fit page control
        fitPageControl()
        
        if count > 0 {
            if circulating {
                if currentRealPage < dummyCount {
                    currentRealPage = dummyCount + currentPage
                } else if currentRealPage > count + dummyCount {
                    currentRealPage = currentRealPage - (count + dummyCount)
                }
                let offset = centeredOffsetForIndex(IndexPath(item: currentRealPage < 0 ? dummyCount : currentRealPage, section: 0))
                collectionView.setContentOffset(offset, animated: false)
            } else {
                currentPage = 0
                currentRealPage = 0
                let offset = centeredOffsetForIndex(IndexPath(item: currentRealPage < 0 ? 0 : currentRealPage, section: 0))
                collectionView.setContentOffset(offset, animated: false)
            }
        }
        prepareForInteraction()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}


// MARK: - Public APIs
extension HFSwipeView {
    
    open func movePage(_ page: Int, animated: Bool) {
        
        if page == currentPage {
            log("movePage received same page(\(page)) == currentPage(\(currentPage))")
            autoAlign(collectionView, indexPath: IndexPath(item: currentRealPage, section: 0))
            return
        }
        let displayIndex = IndexPath(item: page, section: 0)
        let realIndex = closestIndexTo(displayIndex)
        moveRealPage(realIndex.row, animated: animated)
    }
    
    open func deselectItemAtPath(_ indexPath: IndexPath, animated: Bool) {
        collectionView.deselectItem(at: indexPath, animated: animated)
    }
}
