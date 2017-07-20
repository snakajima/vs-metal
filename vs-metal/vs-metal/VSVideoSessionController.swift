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
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime!
    lazy var session:VSCaptureSession = VSCaptureSession(device: self.context.device, pixelFormat: self.context.pixelFormat, delegate: self.context)
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)
    
    // For benchmark
    var frameCount = 0
    var totalTime = CFTimeInterval(0.0)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView,
           let script = VSScript.load(from: urlScript) {
            runtime = script.compile(context: context)
            context.pixelFormat = mtkView.colorPixelFormat
            mtkView.device = context.device
            mtkView.delegate = self
            mtkView.transform = (session.cameraPosition == .front) ? CGAffineTransform(scaleX: -1.0, y: 1.0) : CGAffineTransform.identity
            session.start()
        }
    }
    
    deinit {
        print("Average Elapsed Time = ", totalTime / Double(frameCount))
    }
}

extension VSVideoSessionController : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            let commandBuffer = runtime.encode(commandBuffer: context.makeCommandBuffer(label: "myCompute"), context: context)
            let startTime = CFAbsoluteTimeGetCurrent()
            commandBuffer.addCompletedHandler(){ (_) in
                self.totalTime += CFAbsoluteTimeGetCurrent() - startTime
                self.frameCount += 1
            }
            commandBuffer.commit()
            if let texture = context.pop() {
                renderer.encode(commandBuffer:context.makeCommandBuffer(label: "myRender"), view:view, texture: texture.texture)?
                    .commit()
            }
            context.flush()
        }
    }
}



