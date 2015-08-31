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
//   3. Performace improvment

import UIKit

@IBDesignable
class TabScrollView: UIView, UIScrollViewDelegate {
    
    let DEFAULT_TAB_HEIGHT: CGFloat = 60
    
    @IBInspectable var tabGradient: Bool = true
    @IBInspectable var tabBackgroundColor: UIColor = UIColor.whiteColor()
    @IBInspectable var mainBackgroundColor: UIColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
    
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
                var currentOffset = tabScrollView.contentOffset.x
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
                contentScrollView.contentOffset = CGPoint(x: contentOffsetX, y: contentScrollView.contentOffset.y)
                
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
    
    required init(coder aDecoder: NSCoder) {
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
            
            var tabScrollViewContentWidth: CGFloat = 0
            var contentScrollViewContentWidth: CGFloat = 0
            var tabScrollViewHeight = pages[0].tabView.frame.size.height
            var contentScrollViewHeight = self.frame.size.height - tabScrollViewHeight
            
            // set tabScrollView size
            tabScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabScrollViewHeight)
            tabScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabScrollViewDidClick:"))
            
            // set contentScrollView size
            contentScrollView.frame = CGRect(x: 0, y: tabScrollViewHeight, width: self.frame.size.width, height: contentScrollViewHeight)
            
            // set pages and content views
            for (index, page) in enumerate(pages) {
                page.tabView.frame = CGRect(x: tabScrollViewContentWidth, y: 0, width: page.tabView.frame.size.width, height: page.tabView.frame.size.height)
                //page.contentView.frame = CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: page.contentView.frame.size.height)
                
                // bind event
                page.tabView.tag = index
                page.tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabViewDidClick:"))
                
                tabScrollView.addSubview(page.tabView)
                //contentScrollView.addSubview(page.contentView)
                
                tabScrollViewContentWidth += page.tabView.frame.size.width
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
            tabScrollView.contentSize = CGSize(width: tabScrollViewContentWidth, height: tabScrollViewHeight)
            contentScrollView.contentSize = CGSize(width: contentScrollViewContentWidth, height: contentScrollViewHeight)
            
            // set contentInset of tab
            var paddingLeft = (self.frame.size.width / 2) - (pages[0].tabView.frame.size.width / 2)
            var paddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].tabView.frame.size.width / 2)
            tabScrollView.contentInset = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingRight)
            
            // first time
            if (!isStarted) {
                isStarted = true
                
                // reset pageIndex
                pageIndex = defaultPage
            }
        }
    }
    
    // MARK: - Tabs Click
    func tabViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabScrollView
        changePageTo(sensor.view!.tag, animated: true)
    }
    
    func tabScrollViewDidClick(sensor: UITapGestureRecognizer) {
        activeScrollView = tabScrollView
        changePageTo(pageIndex, animated: true)
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
        if (pagingEnabled) {
            changePageTo(pageIndex, animated: true)
        }
    }
    
    // scrolling animation stop without decelerating
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (pagingEnabled && !decelerate) {
            changePageTo(pageIndex, animated: true)
        }
    }
    
    // scrolling animation stop programmatically
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
    }
    
    // scrolling
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == activeScrollView) {
            if (scrollView == tabScrollView) {
                contentScrollView.contentOffset.x = (tabScrollView.contentOffset.x + tabScrollView.contentInset.left) * (contentScrollView.contentSize.width / tabScrollView.contentSize.width)
            }
            
            if (scrollView == contentScrollView) {
                tabScrollView.contentOffset.x = contentScrollView.contentOffset.x * (tabScrollView.contentSize.width / contentScrollView.contentSize.width) - tabScrollView.contentInset.left
            }
            resetTabs()
        }
        
        if (isStarted && prevScrollingIndex != pageIndex) {
            // lazy load content
            var leftBoundIndex = pageIndex - 1 > 0 ? pageIndex - 1 : 0
            var rightBoundIndex = pageIndex + 1 < pages.count ? pageIndex + 1 : pages.count - 1
            
            var contentScrollViewContentWidth: CGFloat = 0.0
            
            for (var i = 0; i < self.pages.count; i++) {
                var page = self.pages[i]
                
                // add
                if (i >= leftBoundIndex && i <= rightBoundIndex && !page.isLoaded) {
                    page.isLoaded = true
                    page.contentView.frame = CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: page.contentView.frame.size.height)
                    contentScrollView.addSubview(page.contentView)
                }
                // remove
                if ((i < leftBoundIndex || i > rightBoundIndex) && page.isLoaded) {
                    page.isLoaded = false
                    page.contentView.removeFromSuperview()
                }
                
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
            
            prevScrollingIndex = pageIndex
            // callback
            if (delegate != nil) {
                self.delegate!.tabScrollViewDidScrollPage?(pageIndex)
            }
        }
    }
    
    func scroll(offsetX: CGFloat) {
    }
    
    func changePageTo(index: Int, animated: Bool) {
        if (index >= 0 && index < pages.count) {
            // force stop
            stopScrolling()
            
            if (activeScrollView == nil || activeScrollView == tabScrollView) {
                tabScrollView.scrollRectToVisible(pages[index].tabView.frame, animated: animated)
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
    
    func stopScrolling() {
        tabScrollView.setContentOffset(tabScrollView.contentOffset, animated: false)
        contentScrollView.setContentOffset(contentScrollView.contentOffset, animated: false)
    }
    
    func resetTabs() {
        if (tabGradient) {
            var currentIndex = pageIndex
            for (var i = 0; i < pages.count; i++) {
                var alpha: CGFloat = 1.0
                
                var offset = abs(i - currentIndex)
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
}

class Page {
    var tabView: UIView
    var contentView: UIView
    var isLoaded = false
    
    init(tabView: UIView, contentView: UIView) {
        self.tabView = tabView
        self.contentView = contentView
    }
}

@objc protocol TabScrollViewDelegate : NSObjectProtocol {
    
    // triggered by stopping at particular page
    func tabScrollViewDidChangePage(index: Int)
    
    // triggered by scrolling through any pages
    optional func tabScrollViewDidScrollPage(index: Int)
    
    // get pages
    func pages(tabScrollView: TabScrollView) -> [Page]
    
    // get content view at particular page
    func pageContentAtIndex(tabScrollView: TabScrollView, index: Int) -> UIView
    
}
