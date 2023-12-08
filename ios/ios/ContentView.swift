//
//  ContentView.swift
//  ios
//
//  Created by Sergio Ibagy on 11/17/2023.
//

import RustLib
import SwiftUI
import Foundation
import UIKit

class FolderMonitor: NSObject, NSFilePresenter {
    var folderURL: URL
    var presentedItemOperationQueue: OperationQueue
    private var lastProcessedFileURL: URL?
    private var filesToDelete = Set<URL>()
    var count = 0
    
    var onNewImageDetected: ((UIImage) -> Void)?
    
    init(folder: String, onNewImageDetected: @escaping (UIImage) -> Void) {
        self.folderURL = FolderMonitor.createFolder(folder)
        self.onNewImageDetected = onNewImageDetected
        self.presentedItemOperationQueue = OperationQueue.main
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }
    
    var presentedItemURL: URL? {
        return folderURL
    }
    
    func presentedItemDidChange() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            
            let sortedFiles = fileURLs.sorted {
                let date0 = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let date1 = try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                return date0 ?? Date.distantPast > date1 ?? Date.distantPast
            }
            
            // Process only the latest file if it's not the same as the last processed one
            if let latestFileURL = sortedFiles.first, latestFileURL != lastProcessedFileURL {
                processLatestImageFile(latestFileURL)
                lastProcessedFileURL = latestFileURL
            }
            
            // Mark all but the latest file for deletion
            filesToDelete.formUnion(fileURLs.filter { $0 != lastProcessedFileURL })
            deleteMarkedFiles()
        } catch {
            print("Error reading directory contents: \(error)")
        }
    }
    
    private func processLatestImageFile(_ fileURL: URL) {
        if isNewImage(fileURL), let image = UIImage(contentsOfFile: fileURL.path) {
            count += 1
            print("newImage calls: \(count)")
            onNewImageDetected?(image)
        }
    }
    
    private func deleteMarkedFiles() {
        for fileURL in filesToDelete {
            try? FileManager.default.removeItem(at: fileURL)
        }
        filesToDelete.removeAll()
    }
    
    private func isNewImage(_ fileURL: URL) -> Bool {
        // Implement logic to determine if the file is a new image
        return true
    }
    
    // Call this function to stop monitoring
    func stopMonitoring() {
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    static func createFolder(_ folder: String) -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(fileURLWithPath: documentsDirectory)
        let dataPath = docURL.appendingPathComponent(folder)
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            try! FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        }
        print("data folder: \(dataPath)")
        return dataPath
    }
}

class ImageFolderMonitor: ObservableObject {
    @Published var image: UIImage?
    @Published var count = 0
    public var folderMonitor: FolderMonitor?
    
    init(folder: String) {
        folderMonitor = FolderMonitor(folder: folder) { [weak self] newImage in
            DispatchQueue.main.async {
                self?.count += 1
                self?.image = newImage
            }
        }
    }
}


struct ContentView: View {
    @State private var text1 = "Tap to start calling\n(it will call into rust 2x * 50,000,000)"
    @State private var text2 = ""
    @State private var tapCount = 0
    @State private var errorCount = 0
    @State private var rustImage = UIImage(named: "rust-mascot")
    @State private var isLoading = false
    @StateObject private var imageFolderMonitor = ImageFolderMonitor(folder: "images")
    private var imageFetcher = ImageFetcher()
    @State private var isFetching = false
    private let runRust = false
    
    var body: some View {
        VStack {
            Text(text2).padding()
            Text("Call Count: \(imageFolderMonitor.count)").padding(1)
            Text("Error Count: \(errorCount)").padding(1)
            Text("Rust Image fetching").padding()
            Button(isFetching ? "Stop Fetching" : "Start Fetching") {
                if isFetching {
                    if (runRust) {
                        stop_fetch_random_image()
                    } else {
                        imageFetcher.stopFetching()
                    }
                } else {
                    // fetchImageFromRust()
                    if let folderURL = imageFolderMonitor.folderMonitor?.presentedItemURL {
                        let folderPath = folderURL.path
                        print(folderPath)
                        if (runRust) {
                            start_fetch_random_image(folderPath)
                        } else {
                            imageFetcher.startFetching(folderURL)
                        }
                    }
                }
                isFetching.toggle()
            }
            ZStack {
                if let image = imageFolderMonitor.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                if isLoading {
                    TranslucentSpinner()
                }
            }
        }
    }
    
    struct TranslucentSpinner: View {
        var body: some View {
            ZStack {
                // Translucent background
                Color.black.opacity(0.35)
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                
                // Spinner
                ProgressView()
                    .scaleEffect(2)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
