//
//  VSRenderer.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

/// VSRenderer is a helper class (non-essential part of VideoShader), 
/// which makes is easy to render a metal texture to a specified MKTView.
class VSRenderer {
    var orientation = UIDeviceOrientation.portrait
    private var pipelineState: MTLRenderPipelineState?
    
    private struct VSVertex {
        let position:vector_float2
        let textureCoordinate:vector_float2
    }
    private var vertexData = [VSVertex]()
    private var dataSize:Int = 0
    
    /// Initializer
    ///
    /// - Parameter context: VideoShader context
    init(device:MTLDevice, pixelFormat:MTLPixelFormat) {
        
        // load vertex & fragment shaders
        let defaultLibrary = device.newDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        
        // compile them into a pipeline state object
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    /// Encode the rendering instruction to the specified command buffer
    ///
    /// - Parameters:
    ///   - commandBuffer: the command buffer to encode to
    ///   - view: view to render
    /// - Returns: the command buffer
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, view: MTKView, texture:MTLTexture?) -> MTLCommandBuffer? {
        guard let texture = texture else {
            return nil
        }
        if dataSize == 0 {
            // Very first time
            let viewSize = view.bounds.size
            let viewRatio = viewSize.height / viewSize.width
            let size:CGSize
            if orientation == .portrait || orientation == .portraitUpsideDown {
                size = CGSize(width:texture.height, height:texture.width)
            } else {
                size = CGSize(width:texture.width, height:texture.height)
            }
            let ratio = size.height / size.width
            var x = 1.0 as Float
            var y = 1.0 as Float
            if viewRatio < ratio {
                // needs to trim width
                x = Float(viewRatio / ratio)
            } else {
                y = Float(ratio / viewRatio)
            }
            
            // LATER: Lazy implementation
            if orientation == .portrait || orientation == .portraitUpsideDown {
                self.vertexData = [
                    VSVertex(position:[-x, -y], textureCoordinate:[1.0, 1.0]),
                    VSVertex(position:[x,  -y], textureCoordinate:[1.0, 0.0]),
                    VSVertex(position:[-x,  y], textureCoordinate:[0.0, 1.0]),
                    VSVertex(position:[x, -y], textureCoordinate:[1.0, 0.0]),
                    VSVertex(position:[x,  y], textureCoordinate:[0.0, 0.0]),
                    VSVertex(position:[-x,  y], textureCoordinate:[0.0, 1.0]),
                ]
            } else {
                self.vertexData = [
                    VSVertex(position:[-x, -y], textureCoordinate:[0.0, 1.0]),
                    VSVertex(position:[x,  -y], textureCoordinate:[1.0, 1.0]),
                    VSVertex(position:[-x,  y], textureCoordinate:[0.0, 0.0]),
                    VSVertex(position:[x, -y], textureCoordinate:[1.0, 1.0]),
                    VSVertex(position:[x,  y], textureCoordinate:[1.0, 0.0]),
                    VSVertex(position:[-x,  y], textureCoordinate:[0.0, 0.0]),
                ]
            }
            self.dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = self.pipelineState,
              let drawable = view.currentDrawable else {
            print("VSR:draw something is wrong")
            return commandBuffer
        }
        
        // MEMO: Alternatively, we could choose to call makeBlitCommandEncoder() and copy the texture
        // into drawable.texture (we need to set view.framebufferOnly to false), but it means
        // we need to perform mirroring (for front camera) somewhere else. 
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(vertexData, length: dataSize, at: 0)
        encoder.setFragmentTexture(texture, at: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                               vertexCount: vertexData.count,
                               instanceCount: vertexData.count/3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        
        return commandBuffer
    }
}
