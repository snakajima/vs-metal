//
//  SampleViewController2.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class SampleViewController3: UIViewController {
    @IBOutlet var btnRecord:UIBarButtonItem!
    @IBOutlet var btnStop:UIBarButtonItem!
    var recording = false {
        didSet {
            self.btnRecord.isEnabled = !recording
            self.btnStop.isEnabled = recording
        }
    }
    
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    var writer:VSVideoWriter?
    lazy var session:VSCaptureSession = VSCaptureSession(device: self.context.device, pixelFormat: self.context.pixelFormat, delegate: self)

    // For rendering
    var texture:MTLTexture?
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recording = false // force the UI update

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            context.pixelFormat = mtkView.colorPixelFormat
            
            let script = VSScript()
                .mono()
            runtime = script.compile(context: context)

            session.start()
        }
    }
    
    @IBAction func record(sender:UIBarButtonItem) {
        recording = true
        //self.writer = VSVideoWriter(delegate: self)
        //let _ = self.writer?.startWriting(track: track)
    }
    
    @IBAction func stop(sender:UIBarButtonItem) {
        recording = false
    }
}

extension SampleViewController3 : VSCaptureSessionDelegate {
    func didCaptureOutput(session:VSCaptureSession, texture:MTLTexture, presentationTime:CMTime) {
        self.context.set(texture: texture)
        if let commandBuffer = self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context) {
            commandBuffer.addCompletedHandler { (_) in
                DispatchQueue.main.async {
                    self.texture = self.context.pop()?.texture // store it for renderer
                    self.context.flush()
                    //self.writer?.append(texture: self.texture, presentationTime: presentationTime)
                }
            }
            commandBuffer.commit()
        }
    }
}

extension SampleViewController3 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if let texture = self.texture {
            renderer.encode(commandBuffer:commandQueue.makeCommandBuffer(), view:view, texture: texture)?.commit()
        }
    }
}



