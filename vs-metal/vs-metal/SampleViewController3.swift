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
    var startTime:CMTime?
    
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    var writer:VSVideoWriter?
    lazy var session:VSCaptureSession = VSCaptureSession(device: self.context.device, pixelFormat: self.context.pixelFormat, delegate: self)

    // For rendering
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recording = false // force the UI update

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            mtkView.transform = (session.cameraPosition == .front) ? CGAffineTransform(scaleX: -1.0, y: 1.0) : CGAffineTransform.identity
            context.pixelFormat = mtkView.colorPixelFormat
            
            let script = VSScript()
                .mono()
            runtime = script.compile(context: context)

            session.start()
        }
    }
    
    @IBAction func record(sender:UIBarButtonItem) {
        guard let texture = self.context.textureOut?.texture else {
            return
        }
        recording = true
        startTime = nil
        self.writer = VSVideoWriter(delegate: self)
        let size = CGSize(width: texture.width, height: texture.height)
        let _ = self.writer?.startWriting(size: size)
    }
    
    @IBAction func stop(sender:UIBarButtonItem) {
        recording = false
        writer?.finishWriting()
        writer = nil
    }
}

extension SampleViewController3 : VSVideoWriterDelegate {
    func didAppendFrame(writer:VSVideoWriter) {
        //reader?.readNextFrame()
    }
    
    func didFinishWriting(writer: VSVideoWriter, url: URL) {
        recording = false
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = self.btnRecord
        }
        self.present(sheet, animated: true, completion: nil)
    }
}

extension SampleViewController3 : VSCaptureSessionDelegate {
    func didCaptureOutput(session:VSCaptureSession, texture:MTLTexture, presentationTime:CMTime) {
        self.context.set(texture: texture)
        if let commandBuffer = self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context) {
            commandBuffer.addCompletedHandler { (_) in
                DispatchQueue.main.async {
                    self.context.textureOut  = self.context.pop() // store it for renderer
                    self.context.flush()
                    if self.recording {
                        if self.startTime == nil {
                            self.startTime = presentationTime
                        }
                        let relativeTime = CMTimeSubtract(presentationTime, self.startTime!)
                        self.writer?.append(texture: self.context.textureOut?.texture, presentationTime: relativeTime)
                    }
                }
            }
            commandBuffer.commit()
        }
    }
}

extension SampleViewController3 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if let texture = self.context.textureOut?.texture {
            renderer.encode(commandBuffer:commandQueue.makeCommandBuffer(), view:view, texture: texture)?.commit()
        }
    }
}



