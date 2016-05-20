//
//  MockData.swift
//  ACTabScrollView
//
//  Created by Azure Chen on 5/21/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import UIKit

class MockData {

    static let newsArray = [
        News(category: .Entertainment, title: "'Game of Thrones' Kit Harington on falling in love with co-star", section: .Today),
        News(category: .Entertainment, title: "Happy 30th anniversary 'Top Gun'!", section: .Yesterday),
    ]
    
}

enum NewsCategory {
    case Entertainment
    case Tech
    case Sport
    case All
    case Travel
    case Style
    case Features
    case Video
    
    static func allValues() -> [NewsCategory] {
        return [.Entertainment, .Tech, .Sport, .All, .Travel, .Style, .Features, .Video]
    }
}

enum NewsSection {
    case Yesterday
    case Today
}

struct News {
    let category: NewsCategory
    let title: String
    let section: NewsSection
}
