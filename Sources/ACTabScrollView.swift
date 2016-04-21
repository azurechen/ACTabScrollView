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

import UIKit

@IBDesignable
class ACTabScrollView: UIView, UIScrollViewDelegate {
    
    private let DEFAULT_TAB_HEIGHT: CGFloat = 60
    
    // public variables
    @IBInspectable var tabGradient: Bool = true
    @IBInspectable var tabSectionBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable var contentSectionBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable var cachePageLimit: Int = 3
    @IBInspectable var pagingEnabled: Bool = true {
        didSet {
            contentSectionScrollView.pagingEnabled = pagingEnabled
        }
    }
    @IBInspectable var defaultPage = 0
    
    var delegate: ACTabScrollViewDelegate? {
        didSet {
            pages = self.delegate!.pages(self)
        }
    }
    
    private var tabSectionScrollView: UIScrollView!
    private var contentSectionScrollView: UIScrollView!
    
    private var pageIndex: Int {
        get {
            var index = -1
            if (pages.count != 0) {
                let currentOffset = tabSectionScrollView.contentOffset.x
                var startOffset = 0 as CGFloat
                var endOffset = (tabSectionScrollView.contentInset.left * -1) - (pages[0].tabView.frame.size.width / 2)
                
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
                tabSectionScrollView.contentOffset = CGPoint(x: tabOffsetX + tabSectionScrollView.contentInset.left * -1, y: tabSectionScrollView.contentOffset.y)
                contentSectionScrollView.contentOffset = CGPoint(x: contentOffsetX  + contentSectionScrollView.contentInset.left * -1, y: contentSectionScrollView.contentOffset.y)
                
                resetTabs()
            }
            prevPageIndex = index
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
    
    override func drawRect(rect: CGRect) {
        if (pages.count > 0) {
            // set custom attrs
            tabSectionScrollView.backgroundColor = tabSectionBackgroundColor
            contentSectionScrollView.backgroundColor = contentSectionBackgroundColor
            
            // clear all
            for subview in tabSectionScrollView.subviews {
                subview.removeFromSuperview()
            }
            for subview in contentSectionScrollView.subviews {
                subview.removeFromSuperview()
            }
            for page in pages {
                page.isLoaded = false
            }
            
            var tabSectionScrollViewContentWidth: CGFloat = 0
            var contentSectionScrollViewContentWidth: CGFloat = 0
            let tabSectionScrollViewHeight = pages[0].tabView.frame.size.height
            let contentSectionScrollViewHeight = self.frame.size.height - tabSectionScrollViewHeight
            
            // set tabSectionScrollView size
            tabSectionScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabSectionScrollViewHeight)
            tabSectionScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabSectionScrollViewDidClick:"))
            
            // set contentSectionScrollView size
            contentSectionScrollView.frame = CGRect(x: 0, y: tabSectionScrollViewHeight, width: self.frame.size.width, height: contentSectionScrollViewHeight)
            
            // set pages and content views
            for (index, page) in pages.enumerate() {
                page.tabView.frame = CGRect(x: tabSectionScrollViewContentWidth, y: 0, width: page.tabView.frame.size.width, height: tabSectionScrollView.frame.size.height)
                // bind event
                page.tabView.tag = index
                page.tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabViewDidClick:"))
                
                tabSectionScrollView.addSubview(page.tabView)
                
                // without lazy loading
                if (cachePageLimit <= 0) {
                    page.contentView.frame = CGRect(x: contentSectionScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentSectionScrollView.frame.size.height)
                    contentSectionScrollView.addSubview(page.contentView)
                }
                
                tabSectionScrollViewContentWidth += page.tabView.frame.size.width
                contentSectionScrollViewContentWidth += page.contentView.frame.size.width
            }
            tabSectionScrollView.contentSize = CGSize(width: tabSectionScrollViewContentWidth, height: tabSectionScrollViewHeight)
            contentSectionScrollView.contentSize = CGSize(width: contentSectionScrollViewContentWidth, height: contentSectionScrollViewHeight)
            
            // set contentInset of tab
            let tabPaddingLeft = (self.frame.size.width / 2) - (pages[0].tabView.frame.size.width / 2)
            let tabPaddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].tabView.frame.size.width / 2)
            tabSectionScrollView.contentInset = UIEdgeInsets(top: 0, left: tabPaddingLeft, bottom: 0, right: tabPaddingRight)
            
            // set contentInset of content
            let contentPaddingLeft = (self.frame.size.width / 2) - (pages[0].contentView.frame.size.width / 2)
            let contentPaddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].contentView.frame.size.width / 2)
            contentSectionScrollView.contentInset = UIEdgeInsets(top: 0, left: contentPaddingLeft, bottom: 0, right: contentPaddingRight)
            
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
            if (scrollView == tabSectionScrollView) {
                contentSectionScrollView.contentOffset.x = (tabSectionScrollView.contentOffset.x + tabSectionScrollView.contentInset.left) * (contentSectionScrollView.contentSize.width / tabSectionScrollView.contentSize.width) - contentSectionScrollView.contentInset.left
            }
            
            if (scrollView == contentSectionScrollView) {
                tabSectionScrollView.contentOffset.x = (contentSectionScrollView.contentOffset.x + contentSectionScrollView.contentInset.left) * (tabSectionScrollView.contentSize.width / contentSectionScrollView.contentSize.width) - tabSectionScrollView.contentInset.left
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
        activeScrollView = tabSectionScrollView
        moveToIndex(index, animated: animated)
    }
    
    func changePageToIndex(index: Int, animated: Bool, withCallback callback: (Void) -> Void) {
        changePageWaitForCallback = true
        changePageCallback = callback
        changePageToIndex(index, animated: animated)
    }
    
    func stopScrolling() {
        tabSectionScrollView.setContentOffset(tabSectionScrollView.contentOffset, animated: false)
        contentSectionScrollView.setContentOffset(contentSectionScrollView.contentOffset, animated: false)
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
                
                if (activeScrollView == nil || activeScrollView == tabSectionScrollView) {
                    tabSectionScrollView.scrollRectToVisible(pages[index].tabView.frame, animated: animated)
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
            
            
            var contentSectionScrollViewContentWidth: CGFloat = 0.0
            for (var i = 0; i < self.pages.count; i++) {
                let page = self.pages[i]
                
                if (!page.isPrepared && (i < leftBoundIndex || i > rightBoundIndex)) {
                    insertPage(page, frame: CGRect(x: contentSectionScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentSectionScrollView.frame.size.height))
                }
                
                contentSectionScrollViewContentWidth += page.contentView.frame.size.width
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
            
            var contentSectionScrollViewContentWidth: CGFloat = 0.0
            for (var i = 0; i < self.pages.count; i++) {
                let page = self.pages[i]
                
                // add
                if (i >= leftBoundIndex && i <= rightBoundIndex && !page.isLoaded) {
                    insertPage(page, frame: CGRect(x: contentSectionScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: contentSectionScrollView.frame.size.height))
                }
                // remove
                if ((i < leftBoundIndex || i > rightBoundIndex) && page.isLoaded) {
                    removePage(page)
                }
                
                contentSectionScrollViewContentWidth += page.contentView.frame.size.width
            }
        }
    }
    
    private func insertPage(page: Page, frame: CGRect) {
        page.isLoaded = true
        page.isPrepared = true
        page.contentView.frame = frame
        contentSectionScrollView.addSubview(page.contentView)
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

protocol ACTabScrollViewDelegate : NSObjectProtocol {
    
    // triggered by stopping at particular page
    func tabScrollViewDidChangePage(index: Int)
    
    // triggered by scrolling through any pages
    func tabScrollViewDidScrollPage(index: Int)
    
    // get pages
    func pages(tabScrollView: ACTabScrollView) -> [Page]
    
    // get content view at particular page
    func pageContentAtIndex(tabScrollView: ACTabScrollView, index: Int) -> UIView
    
}
