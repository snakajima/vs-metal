//
//  VSVideoSessionController.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class VSVideoSessionController: UIViewController {
    // Public properties to be specified by the callers
    var urlScript:URL?

    // VideoShader properties
    fileprivate var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    lazy fileprivate var renderer:VSRenderer = VSRenderer(context:self.context)
    fileprivate var runtime:VSRuntime!
    lazy private var session:VSCaptureSession = VSCaptureSession(context: self.context)

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("VSVS: view is not an MTKView")
            return
        }

        if let url = urlScript, let script = VSScript.make(url: url) {
            runtime = script.compile(context: context)
            context.pixelFormat = mtkView.colorPixelFormat
            mtkView.device = context.device
            mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            mtkView.delegate = self

            session.start()
        }
    }
}

extension VSVideoSessionController : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // noop
    }
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            do {
                let commandBufferCompute = context.commandQueue.makeCommandBuffer()
                try context.encode(runtime: runtime, commandBuffer: commandBufferCompute)
                commandBufferCompute.commit()
                
                let texture = try context.pop()
                let commandBufferRender = context.commandQueue.makeCommandBuffer()
                renderer.encode(commandBuffer:commandBufferRender, texture:texture.texture, view:view)
                commandBufferRender.commit()
            } catch let error {
                print("#### ERROR #### VSProcessor:draw", error)
            }
            context.flush()
        }
    }
}



