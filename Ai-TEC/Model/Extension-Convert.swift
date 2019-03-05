//
//  Extension-Convert.swift
//  Ai-Tec
//
//  Created by Apple on 10/18/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

extension {
    func convertToDictionary(from text: String) throws -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
}
