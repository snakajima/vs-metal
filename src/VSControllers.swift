//
//  VSControllers.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//
import Foundation
import MetalKit

class VSFork:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture = try context.pop()
        context.push(texture:texture)
        context.push(texture:texture)
    }
}

class VSSwap:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture1 = try context.pop()
        let texture2 = try context.pop()
        context.push(texture:texture1)
        context.push(texture:texture2)
    }
}

class VSDiscard:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let _ = try context.pop()
    }
}

class VSShift:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        context.shift()
    }
}

class VSPrevious:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let texture = context.prev()
        context.push(texture: texture)
    }
}
