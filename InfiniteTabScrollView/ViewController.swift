//
//  ViewController.swift
//  InfiniteTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015年 AzureChen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TabScrollViewDelegate {

    @IBOutlet weak var tabScrollView: TabScrollView!
    
    var pages = [Page]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabScrollView.frame = self.view.frame
        
        self.view.addSubview(tabScrollView)

        let tabViewSize = CGSize(width: 60, height: 60)
        let contentViewSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height - tabViewSize.height)
        for (var i = 0; i < 3; i++) {
            let tabView = UIView(frame: CGRect(x: 0, y: 0, width: tabViewSize.width, height: tabViewSize.height))
            let contentView = UIView(frame: CGRect(x: 0, y: 0, width: contentViewSize.width, height: contentViewSize.height))
            
            switch (i % 3) {
            case 0:
                tabView.backgroundColor = UIColor.redColor()
                contentView.backgroundColor = UIColor.redColor()
            case 1:
                tabView.backgroundColor = UIColor.greenColor()
                contentView.backgroundColor = UIColor.greenColor()
            case 2:
                tabView.backgroundColor = UIColor.blueColor()
                contentView.backgroundColor = UIColor.blueColor()
            default:
                break
            }
            
            
            let page = Page(tabView: tabView, contentView: contentView)
            pages.append(page)
        }
        
        tabScrollView.defaultPage = 1
        tabScrollView.pagingEnabled = true
        tabScrollView.delegate = self
    }

    func tabScrollViewDidChangePage(index: Int) {
        print(index)
    }
    
    func tabScrollViewDidScrollPage(index: Int) {}
    
    func pages(tabScrollView: TabScrollView) -> [Page] {
        return self.pages
    }
    
    func pageContentAtIndex(tabScrollView: TabScrollView, index: Int) -> UIView {
        return self.pages[index].contentView
    }
}

