//
//  VSScript.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit

struct VSScript {
    private let json:[String:Any]
    private init(json:[String:Any]) {
        self.json = json
    }

    var pipeline:[[String:Any]] {
        // pre-validated by make
        return json["pipeline"] as! [[String:Any]]
    }
    
    static func make(url:URL) -> VSScript? {
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String:Any],
               let _ = json["pipeline"] as? [[String:Any]] {
                return VSScript(json: json)
            }
        } catch {
        }
        return nil
    }
}
