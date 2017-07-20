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
    @IBOutlet var mtkView:MTKView!
    @IBOutlet var btnRecord:UIBarButtonItem!
    @IBOutlet var btnStop:UIBarButtonItem!
    var recording = false {
        didSet {
            self.btnRecord.isEnabled = !recording
            self.btnStop.isEnabled = recording
        }
    }
    var startTime:CMTime?
    
    let context = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    var writer:VSVideoWriter?
    lazy var session:VSCaptureSession = VSCaptureSession(device: self.context.device, pixelFormat: self.context.pixelFormat, delegate: self)

    // For rendering
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recording = false // force the UI update

        mtkView.device = context.device
        mtkView.delegate = self
        mtkView.transform = (session.cameraPosition == .front) ? CGAffineTransform(scaleX: -1.0, y: 1.0) : CGAffineTransform.identity
        context.pixelFormat = mtkView.colorPixelFormat
        
        let script = VSScript()
            .gaussian_blur(sigma: 2.0)
            .fork()
            .gaussian_blur(sigma: 2.0)
            .toone()
            .swap()
            .sobel()
            .canny_edge(threshhold: 0.19, thin: 0.5)
            .anti_alias()
            .alpha(ratio: 1.0)
        runtime = script.compile(context: context)

        session.start()
    }
    
    @IBAction func record(sender:UIBarButtonItem) {
        recording = true
        startTime = nil
    }
    
    @IBAction func stop(sender:UIBarButtonItem) {
        recording = false
        writer?.finishWriting()
    }
}

extension SampleViewController3 : VSVideoWriterDelegate {
    func didAppendFrame(writer:VSVideoWriter) {
        //reader?.readNextFrame()
    }
    
    func didFinishWriting(writer: VSVideoWriter, url: URL) {
        recording = false
        self.writer = nil
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.barButtonItem = self.btnRecord
        self.present(sheet, animated: true)
    }
}

extension SampleViewController3 : VSCaptureSessionDelegate {
    func didCaptureOutput(session:VSCaptureSession, texture textureIn:MTLTexture, sampleBuffer:CMSampleBuffer, presentationTime:CMTime) {
        self.context.set(texture: textureIn, sampleBuffer: sampleBuffer)
        if let commandBuffer = self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context) {
            commandBuffer.addCompletedHandler { (_) in
                DispatchQueue.main.async {
                    self.context.textureOut  = self.context.pop() // store it for renderer
                    self.context.flush()
                    guard let textureOut = self.context.textureOut?.texture else {
                        return
                    }
                    if self.writer == nil {
                        print("Sample3: creating a new writer")
                        self.writer = VSVideoWriter(delegate: self)
                        let size = CGSize(width: textureOut.width, height: textureOut.height)
                        let _ = self.writer?.prepare(size: size)
                    }
                    if self.recording {
                        if self.startTime == nil {
                            print("Sample3: start the recording session")
                            self.startTime = presentationTime
                            var transform = CGAffineTransform.identity
                            switch(UIDevice.current.orientation) {
                            case .portrait:
                                transform = transform.rotated(by: .pi/2.0)
                            case .landscapeLeft:
                                transform = transform.rotated(by: .pi)
                            case .portraitUpsideDown:
                                transform = transform.rotated(by: -.pi/2.0)
                            default:
                                break
                            }
                            self.writer?.set(transform: transform)
                            self.writer?.startSession(atSourceTime: presentationTime)
                        }
                        self.writer?.append(texture: textureOut, presentationTime: presentationTime)
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



