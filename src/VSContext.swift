//
//  VSContext.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import MetalPerformanceShaders

// A wrapper of MTLTexture so that we can compare
struct VSTexture:Equatable {
    /// Metal texture
    let texture:MTLTexture
    fileprivate let identity:Int
    public static func ==(lhs: VSTexture, rhs: VSTexture) -> Bool {
        return lhs.identity == rhs.identity
    }
}

class VSContext: NSObject {
    /// Metal device
    let device:MTLDevice
    /// The pixel format of texture
    var pixelFormat = MTLPixelFormat.bgra8Unorm
    /// texture for output (for app to prevent recycling)
    var textureOut:VSTexture?
    /// Becomes true when a source texture is updated
    private(set) var hasUpdate = false

    /// The default group size for Metal shaders
    let threadGroupSize = MTLSizeMake(16,16,1)
    /// The default group count for Metal shaders
    private(set) var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later
    
    private struct NamedBuffer {
        let key:String
        let buffer:MTLBuffer
    }
    
    private let commandQueue: MTLCommandQueue
    private var namedBuffers = [NamedBuffer]()
    private var width = 1, height = 1 // to be set later
    private var descriptor = MTLTextureDescriptor()
    private var sourceTexture:VSTexture?
    
    private var stack = [VSTexture]() // main texture stack
    private var pool = [VSTexture]()  // texture pool for reuse
    private var prevs = [VSTexture]() // layers from previous session
    
    private var frameCount = 0  // only for debugging
    private var droppedFrameCount = 0 // only for debugging
    
    /// Initializer
    ///
    /// - Parameter device: Metal context
    init(device:MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
    }
    
    deinit {
        print("VCS:frame drop rate = ", Float(droppedFrameCount) / Float(frameCount))
    }
        
    /// This function set the video source
    ///
    /// - Parameter texture: texture
    func set(texture:MTLTexture) {
        assert(Thread.current == Thread.main)

        // For the very first time
        if width != texture.width || height != texture.height {
            width = texture.width
            height = texture.height

            // Paranoia
            stack.removeAll()
            pool.removeAll()
            prevs.removeAll()
            
            descriptor.textureType = .type2D
            descriptor.pixelFormat = pixelFormat
            descriptor.width = width
            descriptor.height = height
            descriptor.usage = [.shaderRead, .shaderWrite]
            
            threadGroupCount.width = (width + threadGroupSize.width - 1) / threadGroupSize.width
            threadGroupCount.height = (height + threadGroupSize.height - 1) / threadGroupSize.height
        }

        frameCount += 1 // debug only
        
        if (hasUpdate) {
            // Previous texture has not been processed yet. Ignore the new frame.
            droppedFrameCount += 1 // debug only
            return
        }
        hasUpdate = true
        assert(stack.count < 10) // to detect texture leak (a few is fine for recurring pipeline)
        
        // HACK: I am creating an extra copy to work around the flicker bug described in the following stackflow comment.
        // Extra reference to CVMetalTexture does not solve the problem.
        // https://stackoverflow.com/questions/43550769/holding-onto-a-mtltexture-from-a-cvimagebuffer-causes-stuttering
        let textureCopy:MTLTexture = {
            let textureCopy = device.makeTexture(descriptor: descriptor)
            let commandBuffer:MTLCommandBuffer = {
                let commandBuffer = commandQueue.makeCommandBuffer()
                let encoder = commandBuffer.makeBlitCommandEncoder()
                encoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(width, height, 1), to: textureCopy, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
                encoder.endEncoding()
                return commandBuffer
            }()
            commandBuffer.commit()
            return textureCopy
        }()
        
        sourceTexture = VSTexture(texture:textureCopy, identity:-1)
        push(texture:sourceTexture!)
    }
    
    /// Pop a texture from the texture stack
    ///
    /// - Returns: a texture to be processed by Metal
    /// - Throws: VSContextError.underUnderflow when the stack is empty
    func pop() -> VSTexture? {
        if let texture = stack.popLast() {
            return texture
        }
        return nil
    }
    
    func prev() -> VSTexture {
        if let texture = prevs.popLast() {
            return texture
        }
        print("VSC prev returning source")
        return sourceTexture!
    }
    
    func push(texture:VSTexture) {
        stack.append(texture)
    }
    
    func shift() {
        if let texture = stack.popLast() {
            stack.insert(texture, at: 0)
        }
    }
    
    func getDestination() -> VSTexture {
        // Find a texture in the pool, which is not in the stack
        for texture in pool {
            if !stack.contains(texture) && !prevs.contains(texture) && (textureOut==nil || texture != textureOut!) {
                return texture
            }
        }
        print("VSC:get makeTexture", pool.count)
        return make()
    }
        
    private func make() -> VSTexture {
        let ret = VSTexture(texture:device.makeTexture(descriptor: descriptor), identity:pool.count)
        pool.append(ret)
        return ret
    }

/*
    func encode(commandBuffer:MTLCommandBuffer, runtime:VSRuntime) throws -> MTLCommandBuffer {
        assert(Thread.current == Thread.main)
        
        var dictionary = [String:[Float]]()
        for dynamicVariable in runtime.dynamicVariables {
            dynamicVariable.apply(callback: { (key, values) in
                dictionary[key] = values
            })
        }
        updateNamedBuffers(with: dictionary)
 
        for node in runtime.nodes {
            try node.encode(commandBuffer:commandBuffer, destination:getDestination(), context:self)
        }
        
        return commandBuffer
    }
*/
    
    func flush() {
        hasUpdate = false
        prevs = stack
        stack.removeAll()
    }
    
    func makeCommandBuffer() -> MTLCommandBuffer {
        return commandQueue.makeCommandBuffer()
    }
    
    func registerNamedBuffer(key:String, buffer:MTLBuffer) {
        print("VSC:registerNamedBuffer", key)
        namedBuffers.append(NamedBuffer(key:key, buffer:buffer))
    }
    
    func updateNamedBuffers(with dictionary:[String:[Float]]) {
        for buffer in namedBuffers {
            if let values = dictionary[buffer.key] {
                let length = MemoryLayout.size(ofValue: values[0]) * values.count
                if length <= buffer.buffer.length {
                    memcpy(buffer.buffer.contents(), values, length)
                }
            }
        }
    }
}

extension VSContext: VSCaptureSessionDelegate {
    func didCaptureOutput(session:VSCaptureSession, texture:MTLTexture, presentationTime:CMTime) {
        self.set(texture: texture)
    }
}
