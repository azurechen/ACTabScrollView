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
    
    // get pages
    func pages(tabScrollView: ACTabScrollView) -> [Page]
    
    // get content view at particular page
    func pageContentAtIndex(tabScrollView: ACTabScrollView, index: Int) -> UIView
    
}
