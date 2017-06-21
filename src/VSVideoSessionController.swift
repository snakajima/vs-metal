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

    // Calculated properties
    private var cameraPosition:AVCaptureDevicePosition {
        return useFrontCamera ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back
    }

    // Dynamic properties
    private var session:AVCaptureSession?
    private var camera:AVCaptureDevice?

    // Metal properties
    private static let device = MTLCreateSystemDefaultDevice()!
    fileprivate let textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, VSVideoSessionController.device, nil, &cache)
        return cache!
    }()
    fileprivate var renderer:VSRenderer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("VSVS view is not an MTKView")
            return
        }
        
        mtkView.device = VSVideoSessionController.device
        renderer = VSRenderer(view: mtkView)
        startVideoCaptureSession()
    }

    private func addCamera(session:AVCaptureSession) throws {
        self.camera = nil
        let s = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                mediaType: AVMediaTypeVideo, position: self.cameraPosition)
        if let camera = s?.devices[0] {
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
        }
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
            try addCamera(session:session)
            if let _ = self.camera {
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
                print("session started")
            } else {
                print("no camera")
            }
        } catch {
          print("error")
        }
    }
}

// https://github.com/McZonk/MetalCameraSample

extension VSVideoSessionController : AVCaptureAudioDataOutputSampleBufferDelegate,
                                   AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if captureOutput is AVCaptureVideoDataOutput {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let width = CVPixelBufferGetWidth(pixelBuffer)
                let height = CVPixelBufferGetHeight(pixelBuffer)
                var metalTexture:CVMetalTexture? = nil
                let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &metalTexture)
                if let metalTexture = metalTexture, status == kCVReturnSuccess {
                    renderer?.texture = metalTexture
                } else {
                    print("capture failed")
                }
            }
        } else {
            //print("capture", captureOutput)
        }
    }
}



