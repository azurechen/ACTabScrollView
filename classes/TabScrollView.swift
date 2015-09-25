//
//  TabScrollView.swift
//  InfiniteTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

//  TODO:
//   1. Add a method that can be called when developer need to resize UI on viewDidAppear
//   2. Infinite Scrolling
//   3. Performace improvement
//   4. Adjust the scrolling offset if tabs have diffent widths
//   5. Add paging support if the size of page.contentViews are smaller than tabScrollView size

import UIKit

@IBDesignable
class TabScrollView: UIView, UIScrollViewDelegate {
    
    let DEFAULT_TAB_HEIGHT: CGFloat = 60
    
    @IBInspectable var tabGradient: Bool = true
    @IBInspectable var tabBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable var mainBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable var cachePageLimit: Int = 3
    
    var tabScrollView: UIScrollView!
    var contentScrollView: UIScrollView!
    
    var pagingEnabled: Bool = true {
        didSet {
            contentScrollView.pagingEnabled = pagingEnabled
        }
    }
    var pageIndex: Int {
        get {
            var index = -1
            if (pages.count != 0) {
                let currentOffset = tabScrollView.contentOffset.x
                var startOffset = 0 as CGFloat
                var endOffset = (tabScrollView.contentInset.left * -1) - (pages[0].tabView.frame.size.width / 2)
                
                var boundLeft = 0 as CGFloat
                var boundRight = 0 as CGFloat
                
                for (var i = 0; i < pages.count; i++) {
                    startOffset = endOffset
                    endOffset = startOffset + pages[i].tabView.frame.size.width
                    
                    if (i == 0) {
                        boundLeft = startOffset
                    }
                    if (i == pages.count - 1) {
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
                    index = pages.count - 1
                }
            }
            return index
        }
        set(index) {
            if (pages.count != 0) {
                var tabOffsetX = 0 as CGFloat
                var contentOffsetX = 0 as CGFloat
                for (var i = 0; i < index; i++) {
                    tabOffsetX += pages[index].tabView.frame.size.width
                    contentOffsetX += pages[index].contentView.frame.size.width
                }
                // set default position of tabs and contents
                tabScrollView.contentOffset = CGPoint(x: tabOffsetX + tabScrollView.contentInset.left * -1, y: tabScrollView.contentOffset.y)
                contentScrollView.contentOffset = CGPoint(x: contentOffsetX  + contentScrollView.contentInset.left * -1, y: contentScrollView.contentOffset.y)
                
                resetTabs()
            }
            prevPageIndex = index
        }
    }
    
    var defaultPage = 0
    var delegate: TabScrollViewDelegate? {
        didSet {
            pages = self.delegate!.pages(self)
        }
    }
    
    private var pages = [Page]()
    
    private var isStarted = false
    private var prevScrollingIndex = -1
    private var prevPageIndex = -1
    
    private var changePageWaitForCallback = false
    private var changePageCallback: ((Void) -> (Void))?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // init views
        tabScrollView = UIScrollView()
        contentScrollView = UIScrollView()
        self.addSubview(tabScrollView)
        self.addSubview(contentScrollView)
        
        tabScrollView.pagingEnabled = false
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.showsVerticalScrollIndicator = false
        tabScrollView.delegate = self
        
        contentScrollView.pagingEnabled = pagingEnabled
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.delegate = self
        
        // set init index
        pageIndex = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func drawRect(rect: CGRect) {
        if (pages.count > 0) {
            // set custom attrs
            tabScrollView.backgroundColor = tabBackgroundColor
            contentScrollView.backgroundColor = mainBackgroundColor
            
            // clear all
            for subview in tabScrollView.subviews {
                subview.removeFromSuperview()
            }
            for subview in contentScrollView.subviews {
                subview.removeFromSuperview()
            }
            for page in pages {
                page.isLoaded = false
            }
            
            var tabScrollViewContentWidth: CGFloat = 0
            var contentScrollViewContentWidth: CGFloat = 0
            let tabScrollViewHeight = pages[0].tabView.frame.size.height
            let contentScrollViewHeight = self.frame.size.height - tabScrollViewHeight
            
            // set tabScrollView size
            tabScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabScrollViewHeight)
            tabScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabScrollViewDidClick:"))
            
            // set contentScrollView size
            contentScrollView.frame = CGRect(x: 0, y: tabScrollViewHeight, width: self.frame.size.width, height: contentScrollViewHeight)
            
            // set pages and content views
            for (index, page) in pages.enumerate() {
                page.tabView.frame = CGRect(x: tabScrollViewContentWidth, y: 0, width: page.tabView.frame.size.width, height: tabScrollView.frame.size.height)
                // bind event
                page.tabView.tag = index
                page.tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabViewDidClick:"))
                
                tabScrollView.addSubview(page.tabView)
                
                // without lazy loading
                if (cachePageLimit <= 0) {
                    page.contentView.frame = CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentScrollView.frame.size.height)
                    contentScrollView.addSubview(page.contentView)
                }
                
                tabScrollViewContentWidth += page.tabView.frame.size.width
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
            tabScrollView.contentSize = CGSize(width: tabScrollViewContentWidth, height: tabScrollViewHeight)
            contentScrollView.contentSize = CGSize(width: contentScrollViewContentWidth, height: contentScrollViewHeight)
            
            // set contentInset of tab
            let tabPaddingLeft = (self.frame.size.width / 2) - (pages[0].tabView.frame.size.width / 2)
            let tabPaddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].tabView.frame.size.width / 2)
            tabScrollView.contentInset = UIEdgeInsets(top: 0, left: tabPaddingLeft, bottom: 0, right: tabPaddingRight)
            
            // set contentInset of content
            let contentPaddingLeft = (self.frame.size.width / 2) - (pages[0].contentView.frame.size.width / 2)
            let contentPaddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].contentView.frame.size.width / 2)
            contentScrollView.contentInset = UIEdgeInsets(top: 0, left: contentPaddingLeft, bottom: 0, right: contentPaddingRight)
            
            // first time
            if (!isStarted) {
                // reset pageIndex
                pageIndex = defaultPage
                
                isStarted = true
            }
            lazyLoadPages()
        }
    }
    
    // MARK: - Tabs Click
    func tabViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabScrollView
        moveToIndex(sensor.view!.tag, animated: true)
    }
    
    func tabScrollViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabScrollView
        moveToIndex(pageIndex, animated: true)
    }
    
    // MARK: - Scrolling Control
    var activeScrollView: UIScrollView?
    
    // scrolling animation begin by dragging
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        activeScrollView = scrollView
        // stop current scrolling before start another scrolling
        stopScrolling()
    }
    
    // scrolling animation stop with decelerating
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        moveToIndex(pageIndex, animated: true)
    }
    
    // scrolling animation stop without decelerating
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            moveToIndex(pageIndex, animated: true)
        }
    }
    
    // scrolling animation stop programmatically
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if (changePageWaitForCallback) {
            changePageWaitForCallback = false
            changePageCallback?()
        }
    }
    
    // scrolling
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == activeScrollView) {
            if (scrollView == tabScrollView) {
                contentScrollView.contentOffset.x = (tabScrollView.contentOffset.x + tabScrollView.contentInset.left) * (contentScrollView.contentSize.width / tabScrollView.contentSize.width) - contentScrollView.contentInset.left
            }
            
            if (scrollView == contentScrollView) {
                tabScrollView.contentOffset.x = (contentScrollView.contentOffset.x + contentScrollView.contentInset.left) * (tabScrollView.contentSize.width / contentScrollView.contentSize.width) - tabScrollView.contentInset.left
            }
            resetTabs()
        }
        
        if (isStarted && prevScrollingIndex != pageIndex) {
            // lazy loading
            lazyLoadPages()
            
            prevScrollingIndex = pageIndex
            // callback
            if (delegate != nil) {
                self.delegate!.tabScrollViewDidScrollPage(pageIndex)
            }
        }
    }
    
    func scroll(offsetX: CGFloat) {
    }
    
    func changePageToIndex(index: Int, animated: Bool) {
        activeScrollView = tabScrollView
        moveToIndex(index, animated: animated)
    }
    
    func changePageToIndex(index: Int, animated: Bool, withCallback callback: (Void) -> Void) {
        changePageWaitForCallback = true
        changePageCallback = callback
        changePageToIndex(index, animated: animated)
    }
    
    func stopScrolling() {
        tabScrollView.setContentOffset(tabScrollView.contentOffset, animated: false)
        contentScrollView.setContentOffset(contentScrollView.contentOffset, animated: false)
    }
    
    private func resetTabs() {
        if (tabGradient) {
            let currentIndex = pageIndex
            for (var i = 0; i < pages.count; i++) {
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
                    self.pages[i].tabView.alpha = alpha
                    return
                })
            }
        }
    }
    
    private func moveToIndex(index: Int, animated: Bool) {
        if (index >= 0 && index < pages.count) {
            if (pagingEnabled) {
                // force stop
                stopScrolling()
                
                if (activeScrollView == nil || activeScrollView == tabScrollView) {
                    tabScrollView.scrollRectToVisible(pages[index].tabView.frame, animated: animated)
                }
            }
            
            if (prevPageIndex != index) {
                prevPageIndex = index
                // callback
                if (delegate != nil) {
                    self.delegate!.tabScrollViewDidChangePage(index)
                }
            }
        }
    }
    
    func prepareOtherPages() {
        if (cachePageLimit > 0) {
            let offset = Int(cachePageLimit / 2)
            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
            let rightBoundIndex = pageIndex + offset < pages.count ? pageIndex + offset : pages.count - 1
            
            
            var contentScrollViewContentWidth: CGFloat = 0.0
            for (var i = 0; i < self.pages.count; i++) {
                let page = self.pages[i]
                
                if (!page.isPrepared && (i < leftBoundIndex || i > rightBoundIndex)) {
                    insertPage(page, frame: CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentScrollView.frame.size.height))
                }
                
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
        }
    }
    
    func recycle() {
        if (cachePageLimit > 0) {
            let offset = Int(cachePageLimit / 2)
            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
            let rightBoundIndex = pageIndex + offset < pages.count ? pageIndex + offset : pages.count - 1
            
            for (var i = 0; i < self.pages.count; i++) {
                let page = self.pages[i]
                
                if (page.isPrepared && (i < leftBoundIndex || i > rightBoundIndex)) {
                    self.removePage(page)
                }
            }
        }
    }
    
    private func lazyLoadPages() {
        if (cachePageLimit > 0) {
            let offset = Int(cachePageLimit / 2)
            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
            let rightBoundIndex = pageIndex + offset < pages.count ? pageIndex + offset : pages.count - 1
            
            var contentScrollViewContentWidth: CGFloat = 0.0
            for (var i = 0; i < self.pages.count; i++) {
                let page = self.pages[i]
                
                // add
                if (i >= leftBoundIndex && i <= rightBoundIndex && !page.isLoaded) {
                    insertPage(page, frame: CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentScrollView.frame.size.height))
                }
                // remove
                if ((i < leftBoundIndex || i > rightBoundIndex) && page.isLoaded) {
                    removePage(page)
                }
                
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
        }
    }
    
    private func insertPage(page: Page, frame: CGRect) {
        page.isLoaded = true
        page.isPrepared = true
        page.contentView.frame = frame
        contentScrollView.addSubview(page.contentView)
    }
    
    private func removePage(page: Page) {
        page.isLoaded = false
        page.contentView.removeFromSuperview()
    }
}

class Page {
    var tabView: UIView
    var contentView: UIView
    var isPrepared = false
    var isLoaded = false
    
    init(tabView: UIView, contentView: UIView) {
        self.tabView = tabView
        self.contentView = contentView
    }
}

protocol TabScrollViewDelegate : NSObjectProtocol {
    
    // triggered by stopping at particular page
    func tabScrollViewDidChangePage(index: Int)
    
    // triggered by scrolling through any pages
    func tabScrollViewDidScrollPage(index: Int)
    
    // get pages
    func pages(tabScrollView: TabScrollView) -> [Page]
    
    // get content view at particular page
    func pageContentAtIndex(tabScrollView: TabScrollView, index: Int) -> UIView
    
}
