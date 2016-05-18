//
//  ExampleViewController.swift
//  ACTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015年 AzureChen. All rights reserved.
//

import UIKit

class ExampleViewController: UIViewController, ACTabScrollViewDelegate, ACTabScrollViewDataSource {

    @IBOutlet weak var tabScrollView: ACTabScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabScrollView.defaultPageIndex = 3
        tabScrollView.arrowIndicator = true
        //tabScrollView.defaultTabSectionHeight = 40
        //tabScrollView.pagingEnabled = true
        //tabScrollView.cachePageLimit = 3
        
        tabScrollView.delegate = self
        tabScrollView.dataSource = self
        
        // set navigation bar appearance
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.translucent = false
            navigationBar.tintColor = UIColor.whiteColor()
            navigationBar.barTintColor = UIColor(red: 38.0 / 255, green: 191.0 / 255, blue: 140.0 / 255, alpha: 1)
            navigationBar.titleTextAttributes = NSDictionary(object: UIColor.whiteColor(), forKey: NSForegroundColorAttributeName) as? [String : AnyObject]
            navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            navigationBar.shadowImage = UIImage()
        }
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    }
    
    // MARK: ACTabScrollViewDelegate
    func tabScrollView(tabScrollView: ACTabScrollView, didChangePageTo index: Int) {
        print(index)
    }
    
    func tabScrollView(tabScrollView: ACTabScrollView, didScrollPageTo index: Int) {
    }
    
    // MARK: ACTabScrollViewDataSource
    func numberOfPagesInTabScrollView(tabScrollView: ACTabScrollView) -> Int {
        return 8
    }
    
    func tabScrollView(tabScrollView: ACTabScrollView, tabViewForPageAtIndex index: Int) -> UIView {
        let categories = ["ENTERTAINMENT", "TECH", "SPORT", "ALL", "TRAVEL", "STYLE", "FEATURES", "VIDEO"]
        
        // create a label
        let label = UILabel()
        label.text = categories[index]
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightThin)
        label.textColor = UIColor(red: 77.0 / 255, green: 79.0 / 255, blue: 84.0 / 255, alpha: 1)
        label.textAlignment = .Center
        label.sizeToFit()
        label.frame.size = CGSize(width: label.frame.size.width + 28, height: label.frame.size.height + 36)
        
        return label
    }
    
    func tabScrollView(tabScrollView: ACTabScrollView, contentViewForPageAtIndex index: Int) -> UIView {
        let contentView = UIView()
        
        switch (index % 3) {
        case 0:
            contentView.backgroundColor = UIColor.redColor()
        case 1:
            contentView.backgroundColor = UIColor.greenColor()
        case 2:
            contentView.backgroundColor = UIColor.blueColor()
        default:
            break
        }
        
        return contentView
    }
}

