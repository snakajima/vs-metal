//
//  VSScript+filter.swift
//  vs-metal
//
//  Created by satoshi on 7/2/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation

// MARK: - Helper method to construct a VideoShader script in Swift (Beta)
extension VSScript {
    func alpha(ratio:Float) -> VSScript {
        return append(node: ["name":"alpha", "attr":["ratio":[ratio]]])
    }
}

