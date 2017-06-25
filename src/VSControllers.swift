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
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let texture = context.pop()
        context.push(texture:texture)
        context.push(texture:texture)
    }
}

class VSSwap:VSNode {
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let texture1 = context.pop()
        let texture2 = context.pop()
        context.push(texture:texture1)
        context.push(texture:texture2)
    }
}
