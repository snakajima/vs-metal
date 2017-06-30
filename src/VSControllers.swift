//
//  VSControllers.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//
import Foundation
import MetalKit

struct VSControllers {
    static private let mapping:[String:VSNode] = [
        "fork":     VSFork(),
        "swap":     VSSwap(),
        "discard":  VSDiscard(),
        "shift":    VSShift(),
        "previous": VSPrevious(),
    ]
    static func makeNode(name:String) -> VSNode? {
        return mapping[name]
    }
}

struct VSFork:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture = try context.pop()
        context.push(texture:texture)
        context.push(texture:texture)
    }
}

struct VSSwap:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture1 = try context.pop()
        let texture2 = try context.pop()
        context.push(texture:texture1)
        context.push(texture:texture2)
    }
}

struct VSDiscard:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let _ = try context.pop()
    }
}

struct VSShift:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        context.shift()
    }
}

struct VSPrevious:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture = context.prev()
        context.push(texture: texture)
    }
}
