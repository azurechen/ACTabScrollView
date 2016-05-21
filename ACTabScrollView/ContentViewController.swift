//
//  ContentViewController.swift
//  ACTabScrollView
//
//  Created by Azure Chen on 5/19/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var category: NewsCategory? {
        didSet {
            for news in MockData.newsArray {
                if (news.category == category || category == .All) {
                    newsArray.append(news)
                }
            }
        }
    }
    var newsArray: [News] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let news = newsArray[indexPath.row]
        
        // set the cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! ContentTableViewCell
        cell.thumbnailImageView.image = UIImage(named: "thumbnail-\(news.id)")
        cell.thumbnailImageView.layer.cornerRadius = 4
        cell.titleLabel.text = news.title
        cell.categoryLabel.text = String(news.category)
        cell.categoryView.layer.backgroundColor = UIColor.whiteColor().CGColor
        cell.categoryView.layer.cornerRadius = 4
        cell.categoryView.layer.borderWidth = 1
        cell.categoryView.layer.borderColor = UIColor(red: 238.0 / 255, green: 238.0 / 255, blue: 238.0 / 255, alpha: 1.0).CGColor
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red: 61.0 / 255, green: 66.0 / 255, blue: 77.0 / 255, alpha: 1.0)
        
        let label = UILabel()
        label.text = "Today"
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(17, weight: UIFontWeightThin)
        label.sizeToFit()
        label.frame.origin = CGPoint(x: 18, y: 13)
        
        view.addSubview(label)
        
        return view
    }

}

class ContentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        self.selectionStyle = .None
    }
    
}
