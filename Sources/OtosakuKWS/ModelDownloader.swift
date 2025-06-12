//
//  ModelDownloader.swift
//  OtosakuKWS
//
//  Created by Marat Zainullin on 12/06/2025.
//
//
//

#if canImport(UIKit)
import UIKit
import Foundation
import ZipArchive


final class ModelDownloader: NSObject, URLSessionDownloadDelegate {
    static let shared = ModelDownloader()

    private var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((Result<URL, Error>) -> Void)?
    private var destinationFolder: URL?
    private var remoteURL: URL?
    private var currentTask: URLSessionDownloadTask?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "otosaku.otusaku-kws.download")
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func downloadAndUnzip(from remoteURL: URL,
                          to destinationFolder: URL,
                          progress: @escaping (Float) -> Void,
                          completion: @escaping (Result<URL, Error>) -> Void) {
        self.progressHandler = progress
        self.completionHandler = completion
        self.destinationFolder = destinationFolder
        self.remoteURL = remoteURL

        session.getAllTasks { tasks in
            if let existing = tasks.first(where: { $0.originalRequest?.url == remoteURL }) as? URLSessionDownloadTask {
                self.currentTask = existing
                UserDefaults.standard.set(remoteURL.absoluteString, forKey: "ActiveDownloadURL")
                return
            }

            let task = self.session.downloadTask(with: remoteURL)
            self.currentTask = task
            UserDefaults.standard.set(remoteURL.absoluteString, forKey: "ActiveDownloadURL")
            task.resume()
        }
    }

    func restorePendingDownloadIfNeeded(progress: @escaping (Float) -> Void,
                                        completion: @escaping (Result<URL, Error>) -> Void) {
        guard let urlString = UserDefaults.standard.string(forKey: "ActiveDownloadURL"),
              let url = URL(string: urlString) else { return }

        session.getAllTasks { tasks in
            if let existing = tasks.first(where: { $0.originalRequest?.url == url }) as? URLSessionDownloadTask {
                self.remoteURL = url
                self.progressHandler = progress
                self.completionHandler = completion
                self.currentTask = existing
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fractionCompleted = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler?(fractionCompleted)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destinationFolder else {
            completionHandler?(.failure(NSError(domain: "Missing destination folder", code: 0)))
            return
        }

        do {
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: destinationFolder.path) {
                try fileManager.removeItem(at: destinationFolder)
            }
            try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

            let success = SSZipArchive.unzipFile(atPath: location.path,
                                                 toDestination: destinationFolder.deletingLastPathComponent().path)
            if success {
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: "ActiveDownloadURL")
                    self.completionHandler?(.success(destinationFolder))
                    self.callBackgroundSessionCompletionIfNeeded()
                }
            } else {
                throw NSError(domain: "ModelDownloader", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Unzipping failed"])
            }
        } catch {
            DispatchQueue.main.async {
                UserDefaults.standard.removeObject(forKey: "ActiveDownloadURL")
                self.completionHandler?(.failure(error))
                self.callBackgroundSessionCompletionIfNeeded()
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            DispatchQueue.main.async {
                UserDefaults.standard.removeObject(forKey: "ActiveDownloadURL")
                self.completionHandler?(.failure(error))
                self.callBackgroundSessionCompletionIfNeeded()
            }
        }
    }

    private func callBackgroundSessionCompletionIfNeeded() {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let completion = appDelegate.backgroundSessionCompletionHandler {
                completion()
                appDelegate.backgroundSessionCompletionHandler = nil
            }
        }
    }
}
#endif
