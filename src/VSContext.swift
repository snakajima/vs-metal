//
//  VSContext.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

// A wrapper of MTLTexture so that we can compare
struct VSTexture:Equatable {
    let texture:MTLTexture
    let identity:Int
    public static func ==(lhs: VSTexture, rhs: VSTexture) -> Bool {
        return lhs.identity == rhs.identity
    }
}

class VSContext {
    let device:MTLDevice
    let pixelFormat:MTLPixelFormat
    let threadGroupSize = MTLSizeMake(16,16,1)
    var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later
    let nodes:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()

    private var width = 1, height = 1 // to be set later
    private var descriptor = MTLTextureDescriptor()
    
    // stack: texture stack for the video pipeline
    // transient: popped textures to be migrated to pool later
    // pool: pool of textures to be reused for stack
    private var stack = [VSTexture]()
    private var pool = [VSTexture]()
    var hasUpdate = false
    
    init(device:MTLDevice, pixelFormat:MTLPixelFormat) {
        self.device = device
        self.pixelFormat = pixelFormat
    }
    
    // Special type of push for the video source
    func set(texture:MTLTexture) {
        assert(Thread.current == Thread.main)
        hasUpdate = true
        stack.removeAll() // HACK: for now
        push(texture:VSTexture(texture:texture, identity:-1))
        
        if texture.width==width && texture.height==height {
            return
        }
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
    
    func pop() -> VSTexture {
        if let texture = stack.popLast() {
            return texture
        }
        print("VSC:pop underflow")
        return make() // NOTE: Allow underflow
    }
    
    func push(texture:VSTexture) {
        stack.append(texture)
    }
    
    private func getDestination() -> VSTexture {
        // Find a texture in the pool, which is not in the stack
        for texture in pool {
            guard let _ = stack.index(of:texture) else {
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
    
    func encode(nodes:[VSNode], commandBuffer:MTLCommandBuffer) {
        assert(Thread.current == Thread.main)
        hasUpdate = false
        for node in nodes {
            node.encode(commandBuffer:commandBuffer, destination:getDestination(), context:self)
        }
    }
}
