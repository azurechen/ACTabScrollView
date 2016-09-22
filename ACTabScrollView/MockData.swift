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
        News(id: 1, category: .entertainment, title: "'Game of Thrones' Kit Harington on falling in love with co-star"),
        News(id: 2, category: .tech, title: "How Google plans to bring VR to our homes"),
        News(id: 3, category: .sport, title: "Can Nadal rediscover Paris magic?"),
        News(id: 4, category: .sport, title: "What makes Bayern so special?"),
        News(id: 5, category: .entertainment, title: "Happy 30th anniversary 'Top Gun'!"),
        News(id: 6, category: .travel, title: "How to cook like Asia's best female chef"),
        News(id: 7, category: .travel, title: "Nine reasons to visit Georgia right now"),
        News(id: 8, category: .tech, title: "Look out for self-driving Ubers"),
        News(id: 9, category: .style, title: "This house being built into a cliff, thanks to internet"),
        News(id: 10, category: .specials, title: "Inside Africa"),
        News(id: 11, category: .sport, title: "Hayne named in Fiji's London squad"),
        News(id: 12, category: .travel, title: "Airport security: How can terrorist attacks be prevented?"),
        News(id: 13, category: .specials, title: "Silk Road"),
    ]
    
}

enum NewsCategory {
    case entertainment
    case tech
    case sport
    case all
    case travel
    case style
    case specials
    
    static func allValues() -> [NewsCategory] {
        return [.entertainment, .tech, .sport, .all, .travel, .style, .specials]
    }
}

struct News {
    let id: Int
    let category: NewsCategory
    let title: String
}
