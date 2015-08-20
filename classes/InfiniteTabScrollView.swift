//
//  InfiniteTabScrollView.swift
//  InfiniteTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

import UIKit

class InfiniteTabScrollView: UIView, UIScrollViewDelegate {

    @IBOutlet weak var constHeightOfTabScrollView: NSLayoutConstraint!
    @IBOutlet weak var tabScrollView: UIScrollView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var paggingEnabled = true
    var pageIndex: Int {
        get {
            var currentOffset = tabScrollView.contentOffset.x
            var startOffset = 0 as CGFloat
            var endOffset = (tabScrollView.contentInset.left * -1) - (pages[0].tabView.frame.size.width / 2)
            
            var boundLeft = 0 as CGFloat
            var boundRight = 0 as CGFloat
            
            var index = 0
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
            
            return index
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
            
            // set pages
            var tabScrollViewContentWidth = 0 as CGFloat
            var tabScrollViewContentHeight = pages[0].tabView.frame.size.height
            var contentScrollViewContentWidth = 0 as CGFloat
            var contentScrollViewContentHeight = pages[0].contentView.frame.size.height
            
            for page in pages {
                page.tabView.frame = CGRect(x: tabScrollViewContentWidth, y: 0, width: page.tabView.frame.size.width, height: page.tabView.frame.size.height)
                page.contentView.frame = CGRect(x: contentScrollViewContentWidth, y: 0, width: page.contentView.frame.size.width, height: page.contentView.frame.size.height)
                
                tabScrollView.addSubview(page.tabView)
                contentScrollView.addSubview(page.contentView)
                
                tabScrollViewContentWidth += page.tabView.frame.size.width
                contentScrollViewContentWidth += page.contentView.frame.size.width
            }
            
            // set tabs
            constHeightOfTabScrollView.constant = tabScrollViewContentHeight
            tabScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabScrollViewContentHeight)
            tabScrollView.contentSize = CGSize(width: tabScrollViewContentWidth, height: tabScrollViewContentHeight)
            
            // set contents
            contentScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: contentScrollViewContentHeight)
            contentScrollView.contentSize = CGSize(width: contentScrollViewContentWidth, height: contentScrollViewContentHeight)
            
            // set contentInset of tab
            var paddingLeft = (self.frame.size.width / 2) - (pages[0].tabView.frame.size.width / 2)
            var paddingRight = (self.frame.size.width / 2) - (pages[pages.count - 1].tabView.frame.size.width / 2)
            tabScrollView.contentInset = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingRight)
            tabScrollView.contentOffset = CGPoint(x: tabScrollView.contentInset.left * -1, y: tabScrollView.contentInset.top * -1)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    class func instanceFromNib() -> InfiniteTabScrollView {
        return UINib(nibName: "InfiniteTabScrollView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! InfiniteTabScrollView
    }
    
    override func awakeFromNib() {
        tabScrollView.pagingEnabled = false
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.showsVerticalScrollIndicator = false
        tabScrollView.delegate = self
        
        contentScrollView.pagingEnabled = paggingEnabled
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.delegate = self
    }
    
    override func drawRect(rect: CGRect) {
        
    }
    
    // MARK: - Scrolling Control
    var draggingScrollView: UIScrollView?
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        draggingScrollView = scrollView
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (paggingEnabled && draggingScrollView == tabScrollView) {
            changePageTo(pageIndex, animated: true)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == draggingScrollView) {
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
    
    func changePageTo(index: Int, animated: Bool) {
        // force stop
        tabScrollView.setContentOffset(tabScrollView.contentOffset, animated: false)
        contentScrollView.setContentOffset(contentScrollView.contentOffset, animated: false)
        
        if (index >= 0 && index < pages.count) {
            if (draggingScrollView == tabScrollView) {
                tabScrollView.scrollRectToVisible(pages[index].tabView.frame, animated: animated)
            }
            if (draggingScrollView == contentScrollView) {
                contentScrollView.scrollRectToVisible(pages[index].contentView.frame, animated: animated)
            }
            
//            if (tabDelegate != nil) {
//                self.tabDelegate!.tabScrollViewDidChange(index)
//            }
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
