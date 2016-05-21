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
        News(id: 1, category: .Entertainment, title: "'Game of Thrones' Kit Harington on falling in love with co-star"),
        News(id: 2, category: .Tech, title: "How Google plans to bring VR to our homes"),
        News(id: 3, category: .Sport, title: "Can Nadal rediscover Paris magic?"),
        News(id: 4, category: .Sport, title: "What makes Bayern so special?"),
        News(id: 5, category: .Entertainment, title: "Happy 30th anniversary 'Top Gun'!"),
        News(id: 6, category: .Travel, title: "How to cook like Asia's best female chef"),
        News(id: 7, category: .Travel, title: "Nine reasons to visit Georgia right now"),
        News(id: 8, category: .Tech, title: "Look out for self-driving Ubers"),
        News(id: 9, category: .Style, title: "This house being built into a cliff, thanks to internet"),
        News(id: 10, category: .Specials, title: "Inside Africa"),
        News(id: 11, category: .Sport, title: "Hayne named in Fiji's London squad"),
        News(id: 12, category: .Travel, title: "Airport security: How can terrorist attacks be prevented?"),
        News(id: 13, category: .Specials, title: "Silk Road"),
    ]
    
}

enum NewsCategory {
    case Entertainment
    case Tech
    case Sport
    case All
    case Travel
    case Style
    case Specials
    
    static func allValues() -> [NewsCategory] {
        return [.Entertainment, .Tech, .Sport, .All, .Travel, .Style, .Specials]
    }
}

struct News {
    let id: Int
    let category: NewsCategory
    let title: String
}
