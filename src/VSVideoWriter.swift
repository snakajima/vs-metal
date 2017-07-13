//
//  VSVideoWriter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 7/13/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

enum VSVideoWriterError:Error {
    case failedToLoadSourceAsset
}

class VSVideoWriter {
    public var urlExport:URL?
    
    // For Reading
    private var reader:AVAssetReader?
    private var output:AVAssetReaderTrackOutput?
    private var texture:MTLTexture?
    
    // For writing
    private var writer:AVAssetWriter?
    private var input:AVAssetWriterInput?
    private var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    
    func startSession(urlSource:URL, callback:@escaping (Error?)->Void) -> Bool {
        if self.urlExport == nil {
            // Use the default URL if not specified by the caller
            let fileManager = FileManager.default
            if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let url = documentsURL.appendingPathComponent("export.mov")
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                }
                self.urlExport = url
            }
        }
        
        guard let urlExport = self.urlExport,
              let writer = try? AVAssetWriter(url: urlExport, fileType: AVFileTypeQuickTimeMovie) else {
            print("failed to create a file", self.urlExport ?? "nil")
            return false
        }
        self.writer = writer

        let asset = AVURLAsset(url: urlSource)
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            let status = asset.statusOfValue(forKey: "tracks", error: nil)
            if status == AVKeyValueStatus.loaded,
               let reader = try? AVAssetReader(asset: asset) {
                self.reader = reader
                let track = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
                let settings:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
                self.output = output
                reader.add(output)
                reader.startReading()
                
                let videoSettings: [String : Any] = [
                    AVVideoCodecKey  : AVVideoCodecH264,
                    AVVideoWidthKey  : track.naturalSize.width,
                    AVVideoHeightKey : track.naturalSize.height,
                ]
                let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
                input.transform = track.preferredTransform
                self.input = input
                
                let attrs : [String: Any] = [
                    String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA,
                    String(kCVPixelBufferWidthKey) : track.naturalSize.width,
                    String(kCVPixelBufferHeightKey) : track.naturalSize.height
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
                self.adaptor = adaptor
                
                writer.add(input)
                writer.startWriting()
                writer.startSession(atSourceTime: kCMTimeZero)
                
                callback(nil)
            } else {
                print("failed to create asset reader")
                callback(VSVideoWriterError.failedToLoadSourceAsset)
            }
        }
        return true
    }
}
