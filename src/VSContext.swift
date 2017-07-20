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
    let sampleBuffer:CMSampleBuffer?
    public static func ==(lhs: VSTexture, rhs: VSTexture) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    /// VSRuntime:encode() will call this function in the completion handler.
    public func touchSampleBuffer() {
        if let buffer = sampleBuffer {
            let _ = CMSampleBufferGetPresentationTimeStamp(buffer)
        }
    }
}

/// VSContext object manages the context of video pipeline for a VSRuntime object,
/// such as texture stack and pixel format.
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
    private var skippedFrameCount = 0 // only for debugging
    
    /// Initializer
    ///
    /// - Parameter device: Metal context
    init(device:MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
    }
    
    deinit {
        print("VSContext:frame skip rate = ", skippedFrameCount, frameCount, Float(skippedFrameCount) / Float(frameCount))
    }
    
    var texturesInStack:[VSTexture] {
        return self.stack
    }
        
    /// This function set the video source
    ///
    /// - Parameters:
    ///   - texture: metal texture
    ///   - sampleBuffer: sample buffer the metal texture was created from (optional)
    func set(texture:MTLTexture, sampleBuffer sampleBufferIn:CMSampleBuffer?) {
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
            skippedFrameCount += 1 // debug only
            return
        }
        hasUpdate = true
        assert(stack.count < 10) // to detect texture leak (a few is fine for recurring pipeline)

        // NOTE: We need to retain the sample buffer (if any) until GPU finishes using it. 
        // See VSRuntime.encode() for more details. 
        let sourceTexture = VSTexture(texture:texture, identity:-1, sampleBuffer: sampleBufferIn)
        push(texture:sourceTexture)
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
    
    /// Pop a texture from the previous frame.
    ///
    /// - Returns: a texture from the previous frame
    func prev() -> VSTexture {
        if let texture = prevs.popLast() {
            return texture
        }
        print("VSContext: prev returning source")
        return sourceTexture!
    }
    
    /// Push a texture into the texture stack
    ///
    /// - Parameter texture: a texture
    func push(texture:VSTexture) {
        stack.append(texture)
    }
    
    /// Pop the top most texture and insert it at the bottom of stack
    func shift() {
        if let texture = stack.popLast() {
            stack.insert(texture, at: 0)
        }
    }
    
    /// Return a texture appropriate to write to.
    ///
    /// - Returns: a texture
    func get() -> VSTexture {
        // Find a texture in the pool, which is not in the stack
        for texture in pool {
            if !stack.contains(texture) && !prevs.contains(texture) && (textureOut==nil || texture != textureOut!) {
                return texture
            }
        }
        print("VSContext:get, making a new Texture", pool.count)
        let ret = VSTexture(texture:device.makeTexture(descriptor: descriptor), identity:pool.count, sampleBuffer: nil)
        pool.append(ret)
        return ret
    }
        
    /// Moves all the remaining texture in the current stack to the previous stack,
    /// and resets the hasUpdate property.
    func flush() {
        hasUpdate = false
        prevs = stack
        stack.removeAll()
    }
    
    /// Makes a command buffer for nodes the video pipeline to use
    ///
    /// - Returns: a command buffer
    func makeCommandBuffer() -> MTLCommandBuffer {
        return commandQueue.makeCommandBuffer()
    }
    
    /// Register a named buffer for a NSNode object
    ///
    /// - Parameters:
    ///   - key: name of the buffer
    ///   - buffer: buffer (array of Float)
    func registerNamedBuffer(key:String, buffer:MTLBuffer) {
        print("VSContext:registerNamedBuffer", key)
        namedBuffers.append(NamedBuffer(key:key, buffer:buffer))
    }
    
    /// Update the values of named buffer
    ///
    /// - Parameter dictionary: a dictionary of names and Float values
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
    func didCaptureOutput(session:VSCaptureSession, texture:MTLTexture, sampleBuffer:CMSampleBuffer, presentationTime:CMTime) {
        self.set(texture: texture, sampleBuffer: sampleBuffer)
    }
}
