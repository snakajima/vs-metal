//
//  VSScript+filter.swift
//  vs-metal
//
//  Created by satoshi on 7/2/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation

extension VSScript {
    func mono() -> VSScript {
        append(node: ["name":"mono"])
        return self
    }

    func toone() -> VSScript {
        append(node: ["name":"toone"])
        return self
    }
    
    func gaussian_blur(sigma:Float) -> VSScript {
        append(node: ["name":"gaussian_blur", "attr":["sigma":sigma]])
        return self
    }
}
