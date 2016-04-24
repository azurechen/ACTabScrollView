//
//  ACTabScrollView.swift
//  ACTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

//  TODO:
//   1. Add a method that can be called when developer need to resize UI on viewDidAppear
//   2. Infinite Scrolling
//   3. Performace improvement
//   4. Adjust the scrolling offset if tabs have diffent widths
//   5. Add paging support if the size of page.contentViews are smaller than tabSectionScrollView size
//   6. Test reloadData function

import UIKit

@IBDesignable
public class ACTabScrollView: UIView, UIScrollViewDelegate {
    
    // MARK: Public Variables
    @IBInspectable public var tabGradient: Bool = true
    @IBInspectable public var tabSectionBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable public var contentSectionBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable public var cachePageLimit: Int = 3
    @IBInspectable public var pagingEnabled: Bool = true {
        didSet {
            contentSectionScrollView.pagingEnabled = pagingEnabled
        }
    }
    @IBInspectable public var defaultPage: Int = 0
    @IBInspectable public var defaultTabHeight: CGFloat = 30
    
    public var delegate: ACTabScrollViewDelegate?
    public var dataSource: ACTabScrollViewDataSource?
    
    // MARK: Private Variables
    private var tabSectionScrollView: UIScrollView!
    private var contentSectionScrollView: UIScrollView!
    private var cachedPageTabs: [Int: UIView] = [:]
    private var cachedPageContents: CacheQueue<Int, UIView> = CacheQueue()
    private var realCachePageLimit: Int {
        var limit = 3
        if (cachePageLimit > 3) {
            limit = cachePageLimit
        } else if (cachePageLimit < 1) {
            limit = numberOfPages
        }
        return limit
    }
    
    private var pageIndex: Int {
        get {
            var index = -1
            if (numberOfPages != 0) {
                let currentOffset = tabSectionScrollView.contentOffset.x
                var startOffset = 0 as CGFloat
                var endOffset = (tabSectionScrollView.contentInset.left * -1) - (widthForTabAtIndex(0) / 2)
                
                var boundLeft = 0 as CGFloat
                var boundRight = 0 as CGFloat
                
                for i in 0..<numberOfPages {
                    startOffset = endOffset
                    endOffset = startOffset + widthForTabAtIndex(i)
                    
                    if (i == 0) {
                        boundLeft = startOffset
                    }
                    if (i == numberOfPages - 1) {
                        boundRight = endOffset
                    }
                    
                    if (startOffset <= currentOffset && currentOffset <= endOffset) {
                        index = i
                    }
                }
                
                if (currentOffset < boundLeft) {
                    index = 0
                }
                if (currentOffset > boundRight) {
                    index = numberOfPages - 1
                }
            }
            return index
        }
        set(index) {
            if (numberOfPages != 0) {
                var tabOffsetX = 0 as CGFloat
                var contentOffsetX = 0 as CGFloat
                for (var i = 0; i < index; i++) {
                    tabOffsetX += widthForTabAtIndex(index)
                    contentOffsetX += self.frame.width
                }
                // set default position of tabs and contents
                tabSectionScrollView.contentOffset = CGPoint(x: tabOffsetX + tabSectionScrollView.contentInset.left * -1, y: tabSectionScrollView.contentOffset.y)
                contentSectionScrollView.contentOffset = CGPoint(x: contentOffsetX  + contentSectionScrollView.contentInset.left * -1, y: contentSectionScrollView.contentOffset.y)
                
                updateTabAppearance()
            }
            prevPageIndex = index
        }
    }
    
    private var isStarted = false
    private var prevScrollingIndex = -1
    private var prevPageIndex = -1
    
    private var changePageWaitForCallback = false
    private var changePageCallback: ((Void) -> (Void))?
    
    private var tabSectionHeight: CGFloat = 0
    private var contentSectionHeight: CGFloat = 0
    
    // MARK: DataSource
    private var numberOfPages: Int {
        return dataSource?.numberOfPagesInTabScrollView(self) ?? 0
    }
    
    private func widthForTabAtIndex(index: Int) -> CGFloat {
        return dataSource?.tabScrollView(self, widthForTabAtIndex: index) ?? 0
    }
    
    private func tabViewForPageAtIndex(index: Int) -> UIView? {
        return dataSource?.tabScrollView(self, tabViewForPageAtIndex: index)
    }
    
    private func contentViewForPageAtIndex(index: Int) -> UIView? {
        return dataSource?.tabScrollView(self, contentViewForPageAtIndex: index)
    }
    
    // MARK: Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // init views
        tabSectionScrollView = UIScrollView()
        contentSectionScrollView = UIScrollView()
        self.addSubview(tabSectionScrollView)
        self.addSubview(contentSectionScrollView)
        
        tabSectionScrollView.pagingEnabled = false
        tabSectionScrollView.showsHorizontalScrollIndicator = false
        tabSectionScrollView.showsVerticalScrollIndicator = false
        tabSectionScrollView.delegate = self
        
        contentSectionScrollView.pagingEnabled = pagingEnabled
        contentSectionScrollView.showsHorizontalScrollIndicator = false
        contentSectionScrollView.showsVerticalScrollIndicator = false
        contentSectionScrollView.delegate = self
        
        // set init index
        pageIndex = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override public func drawRect(rect: CGRect) {
        // set custom attrs
        tabSectionScrollView.backgroundColor = tabSectionBackgroundColor
        contentSectionScrollView.backgroundColor = contentSectionBackgroundColor
        
        // reload data
        setupPages()
        
        // first time
        if (!isStarted) {
            // reset pageIndex
            pageIndex = defaultPage
            
            isStarted = true
        }
        
        // load pages
        lazyLoadPages()
    }
    
    // MARK: - Tabs Click
    func tabViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabSectionScrollView
        moveToIndex(sensor.view!.tag, animated: true)
    }
    
    func tabSectionScrollViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabSectionScrollView
        moveToIndex(pageIndex, animated: true)
    }
    
    // MARK: - Scrolling Control
    var activeScrollView: UIScrollView?
    
    // scrolling animation begin by dragging
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        activeScrollView = scrollView
        // stop current scrolling before start another scrolling
        stopScrolling()
    }
    
    // scrolling animation stop with decelerating
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        moveToIndex(pageIndex, animated: true)
    }
    
    // scrolling animation stop without decelerating
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            moveToIndex(pageIndex, animated: true)
        }
    }
    
    // scrolling animation stop programmatically
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if (changePageWaitForCallback) {
            changePageWaitForCallback = false
            changePageCallback?()
        }
    }
    
    // scrolling
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == activeScrollView) {
            if (scrollView == tabSectionScrollView) {
                contentSectionScrollView.contentOffset.x = (tabSectionScrollView.contentOffset.x + tabSectionScrollView.contentInset.left) * (contentSectionScrollView.contentSize.width / tabSectionScrollView.contentSize.width) - contentSectionScrollView.contentInset.left
            }
            
            if (scrollView == contentSectionScrollView) {
                tabSectionScrollView.contentOffset.x = (contentSectionScrollView.contentOffset.x + contentSectionScrollView.contentInset.left) * (tabSectionScrollView.contentSize.width / contentSectionScrollView.contentSize.width) - tabSectionScrollView.contentInset.left
            }
            updateTabAppearance()
        }
        
        if (isStarted && prevScrollingIndex != pageIndex) {
            // lazy loading
            lazyLoadPages()
            
            prevScrollingIndex = pageIndex
            // callback
            if (delegate != nil) {
                self.delegate!.tabScrollView(self, didScrollPageTo: pageIndex)
            }
        }
    }
    
    // MARK: public methods
//    func scroll(offsetX: CGFloat) {
//    }
    
    public func changePageToIndex(index: Int, animated: Bool) {
        activeScrollView = tabSectionScrollView
        moveToIndex(index, animated: animated)
    }
    
    public func changePageToIndex(index: Int, animated: Bool, withCallback callback: (Void) -> Void) {
        changePageWaitForCallback = true
        changePageCallback = callback
        changePageToIndex(index, animated: animated)
    }
    
    // MARK: private methods
    private func stopScrolling() {
        tabSectionScrollView.setContentOffset(tabSectionScrollView.contentOffset, animated: false)
        contentSectionScrollView.setContentOffset(contentSectionScrollView.contentOffset, animated: false)
    }
    
    private func setupPages() {
        // clear all caches
        cachedPageTabs.removeAll()
        for subview in tabSectionScrollView.subviews {
            subview.removeFromSuperview()
        }
        cachedPageContents.removeAll()
        for subview in contentSectionScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        if (numberOfPages != 0) {
            // reset the fixed size of tab section
            tabSectionHeight = defaultTabHeight
            tabSectionScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabSectionHeight)
            tabSectionScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabSectionScrollViewDidClick:"))
            tabSectionScrollView.contentInset = UIEdgeInsets(
                top: 0,
                left: (self.frame.width / 2) - (widthForTabAtIndex(0) / 2),
                bottom: 0,
                right: (self.frame.width / 2) - (widthForTabAtIndex(numberOfPages) / 2))
            
            // reset the fixed size of content section
            contentSectionHeight = self.frame.size.height - tabSectionHeight
            contentSectionScrollView.frame = CGRect(x: 0, y: tabSectionHeight, width: self.frame.size.width, height: contentSectionHeight)
            
            // setup tabs first, and set contents later (lazyLoadPages)
            var tabSectionScrollViewContentWidth: CGFloat = 0
            for i in 0..<numberOfPages {
                if let tabView = tabViewForPageAtIndex(i) {
                    tabView.frame = CGRect(
                        x: tabSectionScrollViewContentWidth,
                        y: 0,
                        width: widthForTabAtIndex(i),
                        height: tabSectionScrollView.frame.size.height)
                    // bind event
                    tabView.tag = i
                    tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabViewDidClick:"))
                    cachedPageTabs[i] = tabView
                    tabSectionScrollView.addSubview(tabView)
                }
                tabSectionScrollViewContentWidth += widthForTabAtIndex(i)
            }
            tabSectionScrollView.contentSize = CGSize(width: tabSectionScrollViewContentWidth, height: tabSectionHeight)
        }
    }
    
    private func updateTabAppearance() {
        if (tabGradient) {
            let currentIndex = pageIndex
            if (numberOfPages != 0) {
                for i in 0..<numberOfPages {
                    var alpha: CGFloat = 1.0
                    
                    let offset = abs(i - currentIndex)
                    if (offset > 1) {
                        alpha = 0.2
                    } else if (offset > 0) {
                        alpha = 0.4
                    } else {
                        alpha = 1.0
                    }
                    
                    UIView.animateWithDuration(NSTimeInterval(0.5), animations: { () in
                        self.cachedPageTabs[i]!.alpha = alpha
                        return
                    })
                }
            }
        }
    }
    
    private func moveToIndex(index: Int, animated: Bool) {
        if (index >= 0 && index < numberOfPages) {
            if (pagingEnabled) {
                // force stop
                stopScrolling()
                
                if (activeScrollView == nil || activeScrollView == tabSectionScrollView) {
                    tabSectionScrollView.scrollRectToVisible(cachedPageTabs[index]!.frame, animated: animated)
                }
            }
            
            if (prevPageIndex != index) {
                prevPageIndex = index
                // callback
                if (delegate != nil) {
                    self.delegate!.tabScrollView(self, didChangePageTo: index)
                }
            }
        }
    }
    
    private func lazyLoadPages() {
        if (numberOfPages != 0) {
            let offset = 1
            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
            let rightBoundIndex = pageIndex + offset < numberOfPages ? pageIndex + offset : numberOfPages - 1
            
            var currentContentWidth: CGFloat = 0.0
            for i in 0..<numberOfPages {
                let width = self.frame.width
                if (i >= leftBoundIndex && i <= rightBoundIndex) {
                    let frame = CGRect(
                        x: currentContentWidth,
                        y: 0,
                        width: width,
                        height: contentSectionScrollView.frame.size.height)
                    insertPageAtIndex(i, frame: frame)
                }
                
                currentContentWidth += width
            }
            contentSectionScrollView.contentSize = CGSize(width: currentContentWidth, height: contentSectionHeight)
            
            // remove older caches
            while (cachedPageContents.count > realCachePageLimit) {
                if let (_, view) = cachedPageContents.popFirst() {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func insertPageAtIndex(index: Int, frame: CGRect) {
        if (cachedPageContents[index] == nil) {
            if let view = contentViewForPageAtIndex(index) {
                view.frame = frame
                cachedPageContents[index] = view
                contentSectionScrollView.addSubview(view)
            }
        } else {
            cachedPageContents.awake(index)
        }
    }
    
//    func prepareOtherPages() {
//        if (cachePageLimit > 0) {
//            let count = dataSource!.numberOfPagesInTabScrollView(self)
//            let offset = Int(cachePageLimit / 2)
//            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
//            let rightBoundIndex = pageIndex + offset < count ? pageIndex + offset : count - 1
//            
//            
//            var contentSectionScrollViewContentWidth: CGFloat = 0.0
//            for (var i = 0; i < count; i++) {
//                let page = self.pages[i]
//                
//                if (!page.isPrepared && (i < leftBoundIndex || i > rightBoundIndex)) {
//                    insertPage(page, frame: CGRect(x: contentSectionScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentSectionScrollView.frame.size.height))
//                }
//                
//                contentSectionScrollViewContentWidth += page.contentView.frame.size.width
//            }
//        }
//    }
//    
//    func recycle() {
//        if (cachePageLimit > 0) {
//            let count = dataSource!.numberOfPagesInTabScrollView(self)
//            let offset = Int(cachePageLimit / 2)
//            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
//            let rightBoundIndex = pageIndex + offset < count ? pageIndex + offset : count - 1
//            
//            for (var i = 0; i < count; i++) {
//                let page = self.pages[i]
//                
//                if (page.isPrepared && (i < leftBoundIndex || i > rightBoundIndex)) {
//                    self.removePage(page)
//                }
//            }
//        }
//    }
//    
//    private func lazyLoadPages() {
//        if (cachePageLimit > 0) {
//            let count = dataSource!.numberOfPagesInTabScrollView(self)
//            let offset = Int(cachePageLimit / 2)
//            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
//            let rightBoundIndex = pageIndex + offset < count ? pageIndex + offset : count - 1
//            
//            var contentSectionScrollViewContentWidth: CGFloat = 0.0
//            for (var i = 0; i < count; i++) {
//                let page = self.pages[i]
//                
//                // add
//                if (i >= leftBoundIndex && i <= rightBoundIndex && !page.isLoaded) {
//                    insertPage(page, frame: CGRect(x: contentSectionScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentSectionScrollView.frame.size.height))
//                }
//                // remove
//                if ((i < leftBoundIndex || i > rightBoundIndex) && page.isLoaded) {
//                    removePage(page)
//                }
//                
//                contentSectionScrollViewContentWidth += page.contentView.frame.size.width
//            }
//        }
//    }
//
//    private func insertPage(page: Page, frame: CGRect) {
//        page.isLoaded = true
//        page.isPrepared = true
//        page.contentView.frame = frame
//        contentSectionScrollView.addSubview(page.contentView)
//    }
//    
//    private func removePage(page: Page) {
//        page.isLoaded = false
//        page.contentView.removeFromSuperview()
//    }
    
    
}

public struct CacheQueue<Key: Hashable, Value> {
    
    var keys: Array<Key> = []
    var values: Dictionary<Key, Value> = [:]
    var count: Int {
        return keys.count
    }
    
    subscript(key: Key) -> Value? {
        get {
            return values[key]
        }
        set {
            // key/value pair exists, delete it first
            if let index = keys.indexOf(key) {
                keys.removeAtIndex(index)
            }
            // append key
            if (newValue != nil) {
                keys.append(key)
            }
            // set value
            values[key] = newValue
        }
    }
    
    mutating func awake(key: Key) {
        if let index = keys.indexOf(key) {
            keys.removeAtIndex(index)
            keys.append(key)
        }
    }
    
    mutating func popFirst() -> (Key, Value)? {
        let key = keys.removeFirst()
        if let value = values.removeValueForKey(key) {
            return (key, value)
        } else {
            return nil
        }
    }
    
    mutating func removeAll() {
        keys.removeAll()
        values.removeAll()
    }
}

//public class Page {
//    var tabView: UIView
//    var contentView: UIView
//    var isPrepared = false
//    var isLoaded = false
//    
//    init(tabView: UIView, contentView: UIView) {
//        self.tabView = tabView
//        self.contentView = contentView
//    }
//}
