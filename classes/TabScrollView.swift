//
//  TabScrollView.swift
//  InfiniteTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

import UIKit

class TabScrollView: UIView, UIScrollViewDelegate {
    
    let DEFAULT_TAB_HEIGHT: CGFloat = 60
    
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
        set {
            // TODO: move to new location
            prevPageIndex = pageIndex
        }
    }
    
    var pages = [Page]() {
        didSet {
            // clear all
            for subview in tabScrollView.subviews {
                subview.removeFromSuperview()
            }
            for subview in contentScrollView.subviews {
                subview.removeFromSuperview()
            }
            
            var tabScrollViewContentWidth = 0 as CGFloat
            var contentScrollViewContentWidth = 0 as CGFloat
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
                page.contentView.frame = CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: page.contentView.frame.size.height)
                
                // bind event
                page.tabView.tag = index
                page.tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabViewDidClick:"))
                
                tabScrollView.addSubview(page.tabView)
                contentScrollView.addSubview(page.contentView)
                
                tabScrollViewContentWidth += page.tabView.frame.size.width
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
            tabScrollView.contentSize = CGSize(width: tabScrollViewContentWidth, height: tabScrollViewHeight)
            contentScrollView.contentSize = CGSize(width: contentScrollViewContentWidth, height: contentScrollViewHeight)
            
            // set contentInset of tab
            var paddingLeft = (self.frame.size.width / 2) - (pages[0].tabView.frame.size.width / 2)
            var paddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].tabView.frame.size.width / 2)
            tabScrollView.contentInset = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingRight)
            tabScrollView.contentOffset = CGPoint(x: tabScrollView.contentInset.left * -1, y: tabScrollView.contentInset.top * -1)
            
            // set init index
            pageIndex = 0
        }
    }
    
    var delegate: TabScrollViewDelegate?
    
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
        contentScrollView.showsHorizontalScrollIndicator = true
        contentScrollView.showsVerticalScrollIndicator = true
        contentScrollView.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func drawRect(rect: CGRect) {
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        activeScrollView = scrollView
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (pagingEnabled) {
            changePageTo(pageIndex, animated: true)
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (pagingEnabled && !decelerate) {
            changePageTo(pageIndex, animated: true)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == activeScrollView) {
            if (scrollView == tabScrollView) {
                contentScrollView.contentOffset.x = (tabScrollView.contentOffset.x + tabScrollView.contentInset.left) * (contentScrollView.contentSize.width / tabScrollView.contentSize.width)
            }
            
            if (scrollView == contentScrollView) {
                tabScrollView.contentOffset.x = contentScrollView.contentOffset.x * (tabScrollView.contentSize.width / contentScrollView.contentSize.width) - tabScrollView.contentInset.left
            }
        }
    }
    
    func scroll(offsetX: CGFloat) {
    }
    
    var prevPageIndex = -1
    func changePageTo(index: Int, animated: Bool) {
        if (index >= 0 && index < pages.count) {
            // force stop
            tabScrollView.setContentOffset(tabScrollView.contentOffset, animated: false)
            contentScrollView.setContentOffset(contentScrollView.contentOffset, animated: false)
            
            if (activeScrollView == nil || activeScrollView == tabScrollView) {
                tabScrollView.scrollRectToVisible(pages[index].tabView.frame, animated: animated)
            }
            
            if (prevPageIndex != index) {
                prevPageIndex = pageIndex
                
                if (delegate != nil) {
                    self.delegate!.tabScrollViewDidPageChange(index)
                }
            }
        }
    }
}

class Page {
    var tabView: UIView
    var contentView: UIView
    
    init(tabView: UIView, contentView: UIView) {
        self.tabView = tabView
        self.contentView = contentView
    }
}

protocol TabScrollViewDelegate : NSObjectProtocol {
    
    func tabScrollViewDidPageChange(index: Int)
    
}
