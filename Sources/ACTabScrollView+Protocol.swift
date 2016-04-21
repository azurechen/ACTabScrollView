//
//  ACTabScrollView+Protocol.swift
//  ACTabScrollView
//
//  Created by Azure_Chen on 2016/4/21.
//  Copyright © 2016年 AzureChen. All rights reserved.
//

import UIKit

public protocol ACTabScrollViewDelegate {
    
    // triggered by stopping at particular page
    func tabScrollView(tabScrollView: ACTabScrollView, didChangePageTo index: Int)
    
    // triggered by scrolling through any pages
    func tabScrollView(tabScrollView: ACTabScrollView, didScrollPageTo index: Int)
}

public protocol ACTabScrollViewDataSource {
    
//    // get pages
//    func pages(tabScrollView: ACTabScrollView) -> [Page]
//    
//    // get content view at particular page
//    func pageContentAtIndex(tabScrollView: ACTabScrollView, index: Int) -> UIView
    
    // get pages count
    func numberOfPagesInTabScrollView(tabScrollView: ACTabScrollView) -> Int
    
    // get the height of tab at index
    func heightForTabInTabScrollView(tabScrollView: ACTabScrollView) -> CGFloat
    
    // get the width of tab at index
    func tabScrollView(tabScrollView: ACTabScrollView, widthForTabAtIndex index: Int) -> CGFloat
    
    // get the tab at index
    func tabScrollView(tabScrollView: ACTabScrollView, tabForPageAtIndex index: Int) -> UIView
    
    // get the width of content at index
    func tabScrollView(tabScrollView: ACTabScrollView, widthForContentAtIndex index: Int) -> CGFloat
    
    // get the content at index
    func tabScrollView(tabScrollView: ACTabScrollView, contentForPageAtIndex index: Int) -> UIView
}
