//
//  ContentViewController.swift
//  ACTabScrollView
//
//  Created by Azure Chen on 5/19/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var category: NewsCategory? {
        didSet {
            for news in MockData.newsArray {
                if (news.category == category || category == .All) {
                    if (news.section == .Today) {
                        todayNews.append(news)
                    } else if (news.section == .Yesterday) {
                        yesterdayNews.append(news)
                    }
                }
            }
        }
    }
    var todayNews: [News] = []
    var yesterdayNews: [News] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.dataSource = self
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? todayNews.count : yesterdayNews.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let news = indexPath.section == 0 ? todayNews[indexPath.row] : yesterdayNews[indexPath.row]
        
        // get cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! ContentTableViewCell
        cell.titleLabel.text = news.title
        return cell
    }

}

class ContentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        self.selectionStyle = .None
    }
    
}
