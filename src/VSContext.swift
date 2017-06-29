//
//  VSContext.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

// A wrapper of MTLTexture so that we can compare
struct VSTexture:Equatable {
    let texture:MTLTexture
    let identity:Int
    public static func ==(lhs: VSTexture, rhs: VSTexture) -> Bool {
        return lhs.identity == rhs.identity
    }
}

private struct NamedBuffer {
    let key:String
    let buffer:MTLBuffer
}

enum VSContextError:Error {
    case stackOverflow
}

class VSContext {
    let device:MTLDevice
    let commandQueue: MTLCommandQueue
    var pixelFormat = MTLPixelFormat.bgra8Unorm
    let threadGroupSize = MTLSizeMake(16,16,1)
    var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later
    let nodes:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()
    private var namedBuffers = [NamedBuffer]()
    var variables = [VSVariable]()
    
    private var width = 1, height = 1 // to be set later
    private var descriptor = MTLTextureDescriptor()
    
    // stack: texture stack for the video pipeline
    // transient: popped textures to be migrated to pool later
    // pool: pool of textures to be reused for stack
    private var stack = [VSTexture]()
    private var pool = [VSTexture]()
    private var prevs = [VSTexture]() // layers from previous session
    var hasUpdate = false
    private var frameCount = 0
    private var droppedFrameCount = 0
    private var sourceTexture:VSTexture?
    
    init(device:MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
    }
    
    deinit {
        print("VCS:frame drop rate = ", Float(droppedFrameCount) / Float(frameCount))
    }
    
    func set(metalTexture:CVMetalTexture) {
        if let texture = CVMetalTextureGetTexture(metalTexture) {
            set(texture:texture)
        }
    }
    
    // Special type of push for the video source
    private func set(texture:MTLTexture) {
        assert(Thread.current == Thread.main)
        
        if width != texture.width || height != texture.height {
            width = texture.width
            height = texture.height
            
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
    
    func pop() throws -> VSTexture {
        if let texture = stack.popLast() {
            return texture
        }
        print("VSC:pop underflow")
        throw VSContextError.stackOverflow
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
    
    private func getDestination() -> VSTexture {
        // Find a texture in the pool, which is not in the stack
        for texture in pool {
            if !stack.contains(texture) && !prevs.contains(texture) {
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
    
    func encode(runtime:VSRuntime, commandBuffer:MTLCommandBuffer) throws {
        assert(Thread.current == Thread.main)
        hasUpdate = false
        
        // prototype
        /*
        let date = NSDate().timeIntervalSince1970
        let ratio = (Float(sin(date * .pi * 2.0)) + 1.0) / 2.0
        let variables = [
            "myratio":[ratio]
        ]
        */
        var vars = [String:[Float]]()
        for variable in variables {
            variable.apply(callback: { (key, values) in
                vars[key] = values
            })
        }
        updateNamedBuffers(with: vars)
 
        for node in runtime.nodes {
            try node.encode(commandBuffer:commandBuffer, destination:getDestination(), context:self)
        }
    }
    
    func flush() {
        prevs = stack
        stack.removeAll()
    }
    
    func registerNamedBuffer(key:String, buffer:MTLBuffer) {
        print("VSC:registerNamedBuffer", key)
        namedBuffers.append(NamedBuffer(key:key, buffer:buffer))
    }
    
    func updateNamedBuffers(with variables:[String:[Float]]) {
        for buffer in namedBuffers {
            if let values = variables[buffer.key] {
                let length = MemoryLayout.size(ofValue: values[0]) * values.count
                if length <= buffer.buffer.length {
                    memcpy(buffer.buffer.contents(), values, length)
                }
            }
        }
    }
}
