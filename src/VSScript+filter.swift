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

    func sobel() -> VSScript {
        append(node: ["name":"sobel"])
        return self
    }

    func canny_edge() -> VSScript {
        append(node: ["name":"canny_edge"])
        return self
    }

    func anti_alias() -> VSScript {
        append(node: ["name":"anti_alias"])
        return self
    }
    
    func gaussian_blur(sigma:Float) -> VSScript {
        append(node: ["name":"gaussian_blur", "attr":["sigma":sigma]])
        return self
    }
    
    func alpha() -> VSScript {
        append(node: ["name":"alpha"])
        return self
    }
}

