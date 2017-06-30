//
//  VSCaptureSession.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/30/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

class VSCaptureSession: NSObject {
    var cameraPosition = AVCaptureDevicePosition.front
    var fps:Int?
    var preset = AVCaptureSessionPreset1280x720

    fileprivate var session:AVCaptureSession?
    fileprivate let context:VSContext
    fileprivate lazy var textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, self.context.device, nil, &cache)
        return cache!
    }()

    init(context:VSContext) {
        self.context = context
    }

    private func addCamera(session:AVCaptureSession) throws -> Bool {
        let s = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                mediaType: AVMediaTypeVideo, position: self.cameraPosition)
        guard let camera = s?.devices[0] else {
            return false
        }
        
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

    func start() {
        let session = AVCaptureSession()
        self.session = nil
        do {
            /* LATER: for audio pipeline
            if let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) {
                let audioInput = try AVCaptureDeviceInput(device: microphone)
                let audioOutput = AVCaptureAudioDataOutput()
                audioOutput.setSampleBufferDelegate(self, queue: .main)
                session.addInput(audioInput)
                session.addOutput(audioOutput)
            }
            */
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

            //session.addOutput(AVCapturePhotoOutput())
            session.startRunning()
            self.session = session
        } catch {
            print("VSVS: failed to start the video capture session")
        }
    }

}

extension VSCaptureSession : AVCaptureAudioDataOutputSampleBufferDelegate,
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

