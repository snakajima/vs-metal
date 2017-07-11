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

    func tint(ratio:Float, red:Float, green:Float, blue:Float, alpha:Float) -> VSScript {
        return append(node: ["name":"tint", "attr":["ratio":ratio, "color":[red, green, blue, alpha]]])
    }

    func enhancer(red:[Float], green:[Float], blue:[Float]) -> VSScript {
        return append(node: ["name":"enhancer", "attr":["red":red, "green":green, "blue":blue]])
    }

    func toone() -> VSScript {
        return append(node: ["name":"toone"])
    }

    func toone(levels:Int) -> VSScript {
        return append(node: ["name":"toone", "attr":["lavels":[Float(levels)]]])
    }

    func boolean(range:Range<Float>, color1:[Float], color2:[Float]) -> VSScript {
        return append(node: ["name":"boolean", "attr":["range":[range.lowerBound, range.upperBound], "color1":color1, "color2":color2]])
    }

    func gradient_map(color1:[Float], color2:[Float]) -> VSScript {
        return append(node: ["name":"gradient_map", "attr":["color1":color1, "color2":color2]])
    }

    func halftone(radius:Float, scale:Float, color1:[Float], color2:[Float]) -> VSScript {
        return append(node: ["name":"halftone", "attr":["radius":radius, "scale":scale, "color1":color1, "color2":color2]])
    }

    func invert() -> VSScript {
        return append(node: ["name":"invert"])
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
    
    func color_tracker(red:Float, green:Float, blue:Float, ratio:Float, range:Range<Float>) -> VSScript {
        return append(node: ["name":"color_tracker", "attr":["color":[red, green, blue], "ratio":[ratio], "range":[range.lowerBound,range.upperBound]]])
    }

    func hue_filter(range:Range<Float>, chroma:Range<Float>) -> VSScript {
        return append(node: ["name":"hue_filter", "attr":["range":[range.lowerBound, range.upperBound], "chroma":[chroma.lowerBound, chroma.upperBound]]])
    }

    func translate(tx:Float, ty:Float) -> VSScript {
        return append(node: ["name":"translate", "attr":["tx":[tx], "ty":[ty]]])
    }

    func transform(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float) -> VSScript {
        return append(node: ["name":"transform", "attr":["abcd":[a, b, c, d], "txty":[tx, ty]]])
    }
}

