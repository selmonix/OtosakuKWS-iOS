//
//  AudioStreamer.swift
//  KWSExample
//
//  Created by Marat Zainullin on 12/06/2025.
//

import Foundation
import AVFoundation

final class AudioStreamer {
    private let engine = AVAudioEngine()
    private let inputBus: AVAudioNodeBus = 0
    private let sampleRate: Double = 16000
    private let frameLength: Double = 3200

    public var onBuffer: (([Double]) -> Void)?
    
    
    init() {
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: inputBus)
        
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: true)!
        
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)!

        inputNode.installTap(onBus: inputBus, bufferSize: UInt32((inputFormat.sampleRate * frameLength) / sampleRate), format: inputFormat) { [weak self] buffer, _ in
            print("b", buffer)
            guard let self else { return }
            var newBufferAvailable = true
            
            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            
            let capacity = AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity)!
            
            var error: NSError?
            let _ = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            
            let intData = convertedBuffer.floatChannelData!
            
            var newFrames: [Double] = []
            for channelIdx in 0..<1 {
                newFrames += Array(UnsafeBufferPointer(start: intData[channelIdx], count: Int(convertedBuffer.frameLength))).map{ Double($0)}
            }
            
            if  newFrames.count != Int(frameLength) {
                print("unexpected buffer length", newFrames.count)
                return
            }
            print("newFrames", newFrames)
            self.onBuffer?(newFrames)
        }
        requestMicrophonePermissions()
    }

    public func start() throws {

        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)
        engine.prepare()
        try engine.start()
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: inputBus)
        engine.stop()
    }
    
    private func requestMicrophonePermissions(
    ) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { isAllowed in
                
            }
        @unknown default: break
            
        }
    }
}
