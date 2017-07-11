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
    lazy var session:VSCaptureSession = VSCaptureSession(context: self.context)
    lazy var renderer:VSRenderer = VSRenderer(context:self.context)

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
}

extension VSVideoSessionController : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            do {
                try runtime.encode(commandBuffer: context.makeCommandBuffer(), context: context)
                           .commit()
                renderer.encode(commandBuffer:context.makeCommandBuffer(), view:view, texture: try? context.pop().texture)?
                           .commit()
            } catch let error {
                print("#### ERROR #### VSProcessor:draw", error)
            }
            context.flush()
        }
    }
}



