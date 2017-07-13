//
//  VSCaptureSession.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/30/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

/// The protocol the client of VSCaptureSesssion must conform to.
protocol VSCaptureSessionDelegate: NSObjectProtocol {
    func didCaptureOutput(session:VSCaptureSession, texture:MTLTexture, presentationTime:CMTime)
}

/// VSCaptureSession is a helper class (non-essential part of VideoShader), which makes it easy to process
/// each video frame in Metal.
class VSCaptureSession: NSObject {
    /// Specifies the camera position (default is front)
    var cameraPosition = AVCaptureDevicePosition.front
    /// Specifies the frame per second (optional)
    var fps:Int?
    /// Specifies the quality level of video frames (default is 720p)
    var preset = AVCaptureSessionPreset1280x720
    
    private let device:MTLDevice
    fileprivate let pixelFormat:MTLPixelFormat
    fileprivate weak var delegate:VSCaptureSessionDelegate?

    fileprivate var session:AVCaptureSession?
    fileprivate lazy var textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, self.device, nil, &cache)
        return cache!
    }()

    /// Initializer
    ///
    /// - Parameters:
    ///   - device: the metal device
    ///   - pixelFormat: pixelFormat of the texture to pass to didCaptureOutput
    ///   - delegate: the delegate object
    init(device:MTLDevice, pixelFormat:MTLPixelFormat, delegate:VSCaptureSessionDelegate) {
        self.device = device
        self.pixelFormat = pixelFormat
        self.delegate = delegate
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

    /// Start the video capture session
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
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
            var metalTexture:CVMetalTexture? = nil
            let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil,
                                                                   pixelFormat, width, height, 0, &metalTexture)
            if let metalTexture = metalTexture, status == kCVReturnSuccess,
               let texture = CVMetalTextureGetTexture(metalTexture) {
                delegate?.didCaptureOutput(session: self, texture: texture, presentationTime: time)
            } else {
                print("VSVS: failed to create texture")
            }
        } else {
            //print("capture", captureOutput)
        }
    }
}

