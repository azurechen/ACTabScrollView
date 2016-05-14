//
//  ACTabScrollView+Protocol.swift
//  ACTabScrollView
//
//  Created by AzureChen on 2016/4/21.
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
    
    // get pages count
    func numberOfPagesInTabScrollView(tabScrollView: ACTabScrollView) -> Int
    
    // get the tab at index
    func tabScrollView(tabScrollView: ACTabScrollView, tabViewForPageAtIndex index: Int) -> UIView
    
    // get the content at index
    func tabScrollView(tabScrollView: ACTabScrollView, contentViewForPageAtIndex index: Int) -> UIView
}
