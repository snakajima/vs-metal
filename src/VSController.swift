//
//  VSController.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//
import Foundation
import MetalKit

/// VSController is a concrete implemtation of VSNode prototol, which represents a controller node.
/// A controller node manipulates the texture stack, and there are five variations:
/// - fork: Duplicate the top most texture
/// - swap: Swap two topmost textures
/// - discard: Discard the top most texture
/// - shift: Shift the topmost texture to the bottom
/// - previous: Push a texture from previous frame
struct VSController : VSNode {
    private var encoder:((MTLCommandBuffer, VSContext) throws -> (Void))

    private static func fork(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let texture = try context.pop()
        context.push(texture:texture)
        context.push(texture:texture)
    }

    private static func swap(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let texture1 = try context.pop()
        let texture2 = try context.pop()
        context.push(texture:texture1)
        context.push(texture:texture2)
    }

    private static func discard(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let _ = try context.pop()
    }

    private static func shift(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        context.shift()
    }

    private static func previous(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let texture = context.prev()
        context.push(texture: texture)
    }

    /// Make a controller node, which conforms to VSNode protocol
    /// This function is called by VSSCript during the compilation process.
    ///
    /// - Parameter name: name of the controller node
    /// - Returns: a new controller node object
    static func makeNode(name:String) -> VSNode? {
        switch(name) {
        case "fork": return VSController(encoder: fork)
        case "swap": return VSController(encoder: swap)
        case "discard": return VSController(encoder: discard)
        case "shift": return VSController(encoder: shift)
        case "previous": return VSController(encoder: previous)
        default: return nil
        }
    }

    /// Manipulate texture stack (such as fork and swap).
    ///
    /// - Parameters:
    ///   - commandBuffer: The command buffer to encode to
    ///   - context: the video pipeline context
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        try encoder(commandBuffer,context)
    }
}
