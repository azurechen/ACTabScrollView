//
//  InfiniteTabScrollView.swift
//  InfiniteTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

import UIKit

class InfiniteTabScrollView: UIView {

    @IBOutlet weak var constHeightOfTabScrollView: NSLayoutConstraint!
    @IBOutlet weak var tabScrollView: UIScrollView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
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
        
        contentScrollView.pagingEnabled = false
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
    }
    
    override func drawRect(rect: CGRect) {
        
        
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
