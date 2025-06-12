// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import OtosakuFeatureExtractor
import CoreML


public class OtosakuKWS {
    
    public var onKeywordDetected: ((String, Double) -> Void)? = nil
    
    private let TAG: String = "OtosakuKWS"
    private let featureExtractor: OtosakuFeatureExtractor
    private let model: OtosakuKWSModel
    private var classes: [String] = []
    private var buffer: [Double] = []
    private let totalFrameLimit = 16000
    private var threshold: Double = 0.9
    
    
    public init (
        modelRootURL: URL,
        featureExtractorRootURL: URL,
        configuration: MLModelConfiguration
    ) throws {
        self.featureExtractor = try OtosakuFeatureExtractor(directoryURL: featureExtractorRootURL)
        self.model = try OtosakuKWSModel(
            url: modelRootURL.appendingPathComponent("CRNNKeywordSpotter.mlmodelc"),
            configuration: configuration
        )
        self.classes = try readClasses(
            from: modelRootURL.appendingPathComponent("classes.txt")
        )
    }
    
    public func handleAudioBuffer(_ buff: [Double]) async {
        guard buff.count < totalFrameLimit,
              totalFrameLimit % buff.count == 0 else {
            print(TAG, "⚠️ Invalid chunk size: \(buff.count)")
            return
        }
        buffer.append(contentsOf: buff)
        if buffer.count > totalFrameLimit {
            buffer.removeFirst(buffer.count - totalFrameLimit)
        }
        
        guard buffer.count == totalFrameLimit else { return }
        
        do {
            var feats = try featureExtractor.processChunk(chunk: buffer)
            
            let probsArray = try model.predict(x: feats)
            
            var (maxProb, bestIdx) = (-1.0, -1)
            for i in 0..<probsArray.count {
                let value = probsArray[i].doubleValue
                if value > maxProb {
                    maxProb = value
                    bestIdx = i
                }
            }
            
            if maxProb > threshold {
                let className = classes[bestIdx]
                await callKeywordDetected(className, maxProb)
            }
            
        } catch {
            print(TAG, "❌ handleAudioBuffer error: \(error)")
        }
    }
    
    public func setProbabilityThreshold(_ threshold: Double) {
        self.threshold = threshold
    }
    
    @MainActor
    private func callKeywordDetected(_ className: String, _ confidence: Double) {
        onKeywordDetected?(className, confidence)
    }
    
    private func readClasses(from url: URL) throws -> [String] {
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.components(separatedBy: .newlines)
        return lines
    }
}

