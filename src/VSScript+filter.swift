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
    func mono() -> VSScript {
        return append(node: ["name":"mono"])
    }

    func color(red:Float, green:Float, blue:Float, alpha:Float) -> VSScript {
        return append(node: ["name":"color", "attr":["color":[red, green, blue, alpha]]])
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
    
    func alpha(ratio:Float) -> VSScript {
        return append(node: ["name":"alpha", "attr":["ratio":[ratio]]])
    }
    
    func color_tracker(red:Float, green:Float, blue:Float, ratio:Float, range:Range<Float>) -> VSScript {
        return append(node: ["name":"color_tracker", "attr":["color":[red, green, blue], "ratio":[ratio], "range":[range.lowerBound,range.upperBound]]])
    }
}

