// The Swift Programming Language
// https://docs.swift.org/swift-book

#if canImport(UIKit)
import Foundation
import OtosakuFeatureExtractor
import CoreML


public class OtosakuKWS {
    private let TAG: String = "OtosakuKWS"
    private let featureExtractor: OtosakuFeatureExtractor
    private let model: OtosakuKWSModel
    private let classes: [String]
    
    private var buffer: [Double] = []
    private let totalFrameLimit = 16000
    private var threshold: Float = 0.9
    
    
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
    
    public func handleAudioBuffer(_ buff: [Double]) throws {
        buffer.append(contentsOf: buff)
        if buffer.count > totalFrameLimit {
            let overflow = buffer.count - totalFrameLimit
            buffer.removeFirst(overflow)
        }
        if buffer.count != totalFrameLimit {
            return
        }
        Task {
            do {
                var feats = try featureExtractor.processChunk(chunk: buffer)
                feats = try featureExtractor.expandDims2D(array: feats)
                let probsArray = try model.predict(x: feats)
                var (max, idx) = (-1.0, -1)
                for i in 0..<probsArray.count {
                    let value = probsArray[i].doubleValue
                    if value > max {
                        max = value
                        idx = i
                    }
                }
                if max > threshold {
                    let currentClass = self.classes[idx]
                }
            } catch {
                print(TAG, "handleAudioBuffer: error: \(error)")
            }
        }
        
    }
    
    public func setProbabilityThreshold(threshold: Float) {
        self.threshold = threshold
    }
    
    public static func downloadAndUnzip(
        from remoteURL: URL,
        to destinationFolder: URL,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let downloader = ModelDownloader.shared
        return downloader.downloadAndUnzip(
            from: remoteURL,
            to: destinationFolder,
            progress: progress,
            completion: completion
        )
    }
    
    
    private func readClasses(from url: URL) throws -> [String] {
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.components(separatedBy: .newlines)
        return lines
    }
}

#endif
