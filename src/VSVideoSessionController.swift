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
  // Public properties
  var useFronCamera = false
  var fps:Int?
 
  // Calculated properties
  var cameraPosition:AVCaptureDevicePosition {
    return useFronCamera ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back
  }
  
  // Dynamic properties
  private var session:AVCaptureSession?
  private var camera:AVCaptureDevice?

  // Metal properties
  static let device = MTLCreateSystemDefaultDevice()!
  let textureCache:CVMetalTextureCache = {
    var cache:CVMetalTextureCache? = nil
    CVMetalTextureCacheCreate(nil, nil, VSVideoSessionController.device, nil, &cache)
    return cache!
  }()
  var renderer:VSRenderer?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let mtkView = self.view as? MTKView {
        mtkView.device = VSVideoSessionController.device
        renderer = VSRenderer(view: mtkView)
        renderer?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
    }

    /*
    metalLayer.device = VideoSessionController.device
    view.layer.addSublayer(metalLayer)
    
    // Debug
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    vertexBuffer = VideoSessionController.device.makeBuffer(bytes:vertexData, length:dataSize, options:[])
    // 1
    let defaultLibrary = VideoSessionController.device.newDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "vertexPassthrough")
    // 2
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    // 3
    pipelineState = try! VideoSessionController.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    commandQueue = VideoSessionController.device.makeCommandQueue()
    */
    
    startVideoCaptureSession()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destinationViewController.
      // Pass the selected object to the new view controller.
  }
  */
  
  private func addCamera(session:AVCaptureSession) throws {
    self.camera = nil
    let s = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                            mediaType: AVMediaTypeVideo, position: self.cameraPosition)
    if let device = s?.devices[0] {
      self.camera = device
      let preset = AVCaptureSessionPreset1280x720
      if device.supportsAVCaptureSessionPreset(preset) {
        session.sessionPreset = preset
      }
      let cameraInput = try AVCaptureDeviceInput(device: device)
      session.addInput(cameraInput)
      
      if let fps = self.fps {
        try device.lockForConfiguration()
        device.activeVideoMinFrameDuration = CMTimeMake(1, Int32(fps))
        device.unlockForConfiguration()
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
    // to be implemented
    if captureOutput is AVCaptureVideoDataOutput {
      
      if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var metalTexture:CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, MTLPixelFormat.r8Unorm, width, height, 0, &metalTexture)
        if let metalTexture = metalTexture, status == kCVReturnSuccess,
           let texture = CVMetalTextureGetTexture(metalTexture) {
           renderer?.texture = texture
          //print("capture", width, height, texture)
        } else {
          print("capture failed")
        }
      }
    } else {
      //print("capture", captureOutput)
    }
  }
}



