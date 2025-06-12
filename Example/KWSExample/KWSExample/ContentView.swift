//
//  ContentView.swift
//  KWSExample
//
//  Created by Marat Zainullin on 12/06/2025.
//

import SwiftUI
import OtosakuKWS

struct ContentView: View {
    @ObservedObject private var observer: Observer = Observer()

    var body: some View {
        VStack(spacing: 24) {
            Text("🎙️ Otosaku KWS Demo")
                .font(.largeTitle.bold())

            if let keyword = observer.detectedKeyword, let score = observer.confidence {
                Text("✅ Detected: **\(keyword)**")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("Confidence: \(String(format: "%.2f", score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Listening...")
                    .font(.title2)
                    .foregroundColor(.gray)
            }

            if observer.recordWasStarted {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            observer.startRecording()
//            setupKWS()
        }
        .onDisappear {
            observer.stop()
        }
    }

//    private func setupKWS() {
//        Task {
//            do {
//                let modelRoot = Bundle.main.resourceURL!
//                let featurizerRoot = Bundle.main.resourceURL!
//
//                let kws = try OtosakuKWS(
//                    modelRootURL: modelRoot,
//                    featureExtractorRootURL: featurizerRoot,
//                    configuration: .init()
//                )
//
//                kws.setProbabilityThreshold(0.9)
//
//                kws.onKeywordDetected = { keyword, score in
//                    detectedKeyword = keyword
//                    confidence = score
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                        detectedKeyword = nil
//                        confidence = nil
//                    }
//                }
//
//                let audioInput = AudioStreamer()
//
//                audioInput.onBuffer = { buffer in
//                    Task {
//                        await kws.handleAudioBuffer(buffer)
//                    }
//                }
//
//                try audioInput.start()
//            } catch {
//                print("🚨 Error setting up KWS: \(error)")
//            }
//        }
//    }
}
