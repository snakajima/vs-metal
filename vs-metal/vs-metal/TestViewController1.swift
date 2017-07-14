//
//  TestViewController1.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class TestViewController1: UIViewController {
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
    
    var device = MTLCreateSystemDefaultDevice()!
    var texture:MTLTexture?
    var writer:VSVideoWriter?
    lazy var session:VSCaptureSession = VSCaptureSession(device: self.device, pixelFormat: self.mtkView.colorPixelFormat, delegate: self)

    // For rendering
    lazy var commandQueue:MTLCommandQueue = self.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.device, pixelFormat:self.mtkView.colorPixelFormat)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recording = false // force the UI update

        mtkView.device = device
        mtkView.delegate = self
        mtkView.transform = (session.cameraPosition == .front) ? CGAffineTransform(scaleX: -1.0, y: 1.0) : CGAffineTransform.identity
        
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

extension TestViewController1 : VSVideoWriterDelegate {
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

extension TestViewController1 : VSCaptureSessionDelegate {
    func didCaptureOutput(session:VSCaptureSession, texture textureIn:MTLTexture, sampleBuffer:CMSampleBuffer, presentationTime:CMTime) {
        // Intentionally adding async
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
        //DispatchQueue.main.async {
            self.texture = textureIn
            if self.writer == nil {
                print("Sample3: creating a new writer")
                self.writer = VSVideoWriter(delegate: self)
                let size = CGSize(width: textureIn.width, height: textureIn.height)
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
                self.writer?.append(texture: textureIn, presentationTime: presentationTime)
            }
        }
    }
}

extension TestViewController1 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if let texture = self.texture {
            renderer.encode(commandBuffer:commandQueue.makeCommandBuffer(), view:view, texture: texture)?.commit()
        }
    }
}



