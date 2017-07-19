//
//  VSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

/// VSFilter is a concrete implemtation of VSNode prototol, which represents a filter node.
/// A filter node takes zero or more textures from the stack as input, 
/// and push a generated texture to the stack.
/// VSNode objects are created by a Script object when its compile() method is called.
struct VSFilter: VSNode {
    private let pipelineState:MTLComputePipelineState
    private let paramBuffers:[MTLBuffer]
    private let sourceCount:Int
    
    private init(pipelineState:MTLComputePipelineState, buffers:[MTLBuffer], sourceCount:Int) {
        self.pipelineState = pipelineState
        self.paramBuffers = buffers
        self.sourceCount = sourceCount
    }

    /// Make a filter object, which conforms to VSNode protocol.
    /// This function is called by VSSCript during the compilation process.
    ///
    /// - Parameters:
    ///   - nodeName: name of the node, which is the name of Metal kernel
    ///   - buffers: named buffers (attributes)
    ///   - sourceCount: number of input textures
    ///   - device: metal device
    /// - Returns: a VSNode object
    static func makeNode(name nodeName:String, buffers:[MTLBuffer], sourceCount:Int, device:MTLDevice) -> VSNode? {
        guard let kernel = device.newDefaultLibrary()!.makeFunction(name: nodeName) else {
            print("### VSScript:makeNode failed to create kernel", nodeName)
            return nil
        }
        do {
            let pipelineState = try device.makeComputePipelineState(function: kernel)
            return VSFilter(pipelineState: pipelineState, buffers: buffers, sourceCount:sourceCount)
        } catch {
            print("### VSScript:makeNode failed to create pipeline state", nodeName)
        }
        return nil
    }
    
    /// Encode appropriate GPU instructions into the command buffer.
    ///
    /// - Parameters:
    ///   - commandBuffer: The command buffer to encode to
    ///   - context: the video pipeline context
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        let destination = context.get() // must be called before any stack operation
        
        for index in 0..<sourceCount {
            if let texture = context.pop() {
                encoder.setTexture(texture.texture, at: index)
            }
        }
        encoder.setTexture(destination.texture, at: sourceCount)
        for (index, buffer) in paramBuffers.enumerated() {
            encoder.setBuffer(buffer, offset: 0, at: sourceCount + 1 + index)
        }
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
        context.push(texture:destination)
    }
}
