//
//  Observer.swift
//  KWSExample
//
//  Created by Marat Zainullin on 12/06/2025.
//

import SwiftUI
import AVFoundation
import OtosakuKWS

class Observer: ObservableObject {
    
    private let outputBufferSize: Double = 3200
    private let outputSampleRate: Double = 16000
    private var audioEngine: AVAudioEngine!
    private var audioInputNode: AVAudioInputNode!
    private var kws: OtosakuKWS?
    @Published var recordWasStarted: Bool = false
    @Published  var detectedKeyword: String? = nil
    @Published  var confidence: Double? = nil
    
    private var buffer: [Double] = []
    
    
    init () {
        try! initKWS()
        audioEngine = AVAudioEngine()
        audioInputNode = audioEngine.inputNode
        
        let bus = 0
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: bus)
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: outputSampleRate, channels: 1, interleaved: true)!
        
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        audioInputNode.installTap(onBus: 0, bufferSize: UInt32((inputFormat.sampleRate * outputBufferSize) / outputSampleRate), format: inputFormat) { (buffer, time) in
            
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
            
            self.handleAudioBuffer(convertedBuffer)
        }
        
        requestMicrophonePermissions()
    }
    
    func startRecording() {
        recordWasStarted = true
        do {
            try audioEngine.start()
        } catch {
            print("AVAudioEngine: \(error)")
        }
    }
    
    
    func stop() {
        recordWasStarted = false
        audioEngine.stop()
    }
    
    func handleAudioBuffer(_ buff: AVAudioPCMBuffer) {
        let intData = buff.floatChannelData!
        
        var newFrames: [Double] = []
        for channelIdx in 0..<1 {
            newFrames += Array(UnsafeBufferPointer(start: intData[channelIdx], count: Int(buff.frameLength))).map{ Double($0)}
        }
        
        
        if  newFrames.count != 3200 {
            print("buffer size", newFrames.count)
            return
        }
        
        Task {
            await kws?.handleAudioBuffer(newFrames)
        }
        
        
    }
    
    private func initKWS() throws {
        let modelRoot = Bundle.main.resourceURL!
        let featurizerRoot = Bundle.main.resourceURL!

        kws = try OtosakuKWS(
            modelRootURL: modelRoot,
            featureExtractorRootURL: featurizerRoot,
            configuration: .init()
        )

        kws?.setProbabilityThreshold(0.9)

        kws?.onKeywordDetected = { [weak self] keyword, score in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.detectedKeyword = keyword
                self.confidence = score

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.detectedKeyword = nil
                    self.confidence = nil
                }
            }
            
        }
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
