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
    var useFrontCamera = true
    var fps:Int?
    var urlScript:URL?

    // Calculated properties
    private var cameraPosition:AVCaptureDevicePosition {
        return useFrontCamera ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back
    }

    // Dynamic properties
    private var session:AVCaptureSession?
    private var camera:AVCaptureDevice?

    // Metal properties
    fileprivate lazy var textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, self.context.device, nil, &cache)
        return cache!
    }()
    
    // VideoShader properties
    fileprivate var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    lazy fileprivate var renderer:VSRenderer = VSRenderer(context:self.context)
    fileprivate var runtime:VSRuntime!

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
            
            startVideoCaptureSession()
        }
    }

    private func addCamera(session:AVCaptureSession) throws -> Bool {
        let s = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                mediaType: AVMediaTypeVideo, position: self.cameraPosition)
        guard let camera = s?.devices[0] else {
            self.camera = nil
            return false
        }
        
        self.camera = camera
        let preset = AVCaptureSessionPreset1280x720
        if camera.supportsAVCaptureSessionPreset(preset) {
            session.sessionPreset = preset
        }
        let cameraInput = try AVCaptureDeviceInput(device: camera)
        session.addInput(cameraInput)

        if let fps = self.fps {
            try camera.lockForConfiguration()
            camera.activeVideoMinFrameDuration = CMTimeMake(1, Int32(fps))
            camera.unlockForConfiguration()
        }
        return true
    }

    private func startVideoCaptureSession() {
        let session = AVCaptureSession()
        self.session = nil
        do {
            if let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) {
                let audioInput = try AVCaptureDeviceInput(device: microphone)
                let audioOutput = AVCaptureAudioDataOutput()
                audioOutput.setSampleBufferDelegate(self, queue: .main)
                session.addInput(audioInput)
                session.addOutput(audioOutput)
            }
            guard try addCamera(session:session) else {
                print("VSVS: no camera on this device")
                return
            }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [
              kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: .main)
            session.addOutput(videoOutput)

            let imageOutput = AVCapturePhotoOutput()
            session.addOutput(imageOutput)

            self.session = session
            session.startRunning()
        } catch {
          print("VSVS: failed to start the video capture session")
        }
    }
}

// https://github.com/McZonk/MetalCameraSample

extension VSVideoSessionController : AVCaptureAudioDataOutputSampleBufferDelegate,
                                   AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if captureOutput is AVCaptureVideoDataOutput,
           let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
            var metalTexture:CVMetalTexture? = nil
            let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil,
                                                                   context.pixelFormat, width, height, 0, &metalTexture)
            if let metalTexture = metalTexture, status == kCVReturnSuccess {
                context.set(metalTexture: metalTexture)
            } else {
                print("VSVS: failed to create texture")
            }
        } else {
            //print("capture", captureOutput)
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


