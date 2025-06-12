//
//  OtosakuKWSModel.swift
//  OtosakuKWS
//
//  Created by Marat Zainullin on 12/06/2025.
//

import CoreML
import Foundation

enum OtosakuKWSModelPredictError: Error {
    case outputExtractionFailed
}

class OtosakuKWSModel {
    private let model: MLModel
    
    public init (url: URL, configuration: MLModelConfiguration) throws {
        model = try MLModel(contentsOf: url, configuration: configuration)
    }
    
    public func predict(x: MLMultiArray) throws -> MLMultiArray {
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: [
            "input": x
        ])
        let out = try model.prediction(from: featureProvider)
        guard let probs = out.featureValue(for: "probs")?.multiArrayValue else {
            throw OtosakuKWSModelPredictError.outputExtractionFailed
        }
        
        return probs
    }
}
