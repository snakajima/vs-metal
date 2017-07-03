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
        return append(node: ["name":"mono"])
    }

    func toone() -> VSScript {
        return append(node: ["name":"toone"])
    }

    func sobel() -> VSScript {
        return append(node: ["name":"sobel"])
    }

    func canny_edge(threshhold:Float, thin:Float) -> VSScript {
        return append(node: ["name":"canny_edge", "attr":["threshhold":[threshhold], "thin":[thin]]])
    }

    func anti_alias() -> VSScript {
        return append(node: ["name":"anti_alias"])
    }
    
    func gaussian_blur(sigma:Float) -> VSScript {
        return append(node: ["name":"gaussian_blur", "attr":["sigma":[sigma]]])
    }
    
    func alpha() -> VSScript {
        return append(node: ["name":"alpha"])
    }
}
