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

// Global function for posting notification
func postImageFetchNotification(dataPtr: UnsafePointer<UInt8>?, length: UInt) {
    print("Swift: Posting Image Fetch Notification \(length)")
    guard let dataPtr = dataPtr else {
        print("Swift: postImageFetchNotification: invalid data, posting")
        NotificationCenter.default.post(
            name: .ImageFetchCompleted, object: nil, userInfo: ["data": Data()])
        print("Swift: postImageFetchNotification: invalid data, posted, returning")
        return
    }
    
    print("Swift: postImageFetchNotification: data is valid")
    let data = Data(bytes: dataPtr, count: Int(length))
    NotificationCenter.default.post(
        name: .ImageFetchCompleted, object: nil, userInfo: ["data": data])
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
    @State private var tapCount = 0  // Add a state property for the tap count
    @State private var errorCount = 0
    @State private var rustImage = UIImage(named: "rust-mascot")
    @State private var isLoading = false  // State to track loading status
    @StateObject private var imageFolderMonitor = ImageFolderMonitor(folder: "images")
    
    var body: some View {
        VStack {
            Text(text1).padding()
                .onTapGesture {
                    handleOnTap()
                }
            Text(text2).padding()
            Text("Call Count: \(imageFolderMonitor.count)").padding(1)
            Text("Error Count: \(errorCount)").padding(1)
            Text("Rust Image fetching")
            HStack {
                Button("Start") {
                    // fetchImageFromRust()
                    // saveImageToFolder()
                    if let folderURL = imageFolderMonitor.folderMonitor?.presentedItemURL {
                        let folderPath = folderURL.path
                        print(folderPath)
                        start_fetch_random_image(folderPath)
                    }
                }.padding()
                Button("Stop") {
                    stop_fetch_random_image()
                }
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
        //        .onChange(of: imageFolderMonitor.image) { _ in
        //            tapCount += 1
        //        }
        // .onReceive([self.isLoading].publisher.first(), perform: { value in
        //     print("isLoading changed to \(value)")
        // })
        .onAppear {
            //            setUpNotificationObserver()
        }
    }
    
    private func saveImageToFolder() {
        if let image = UIImage(named: "rust-mascot"),
           let imageData = image.pngData() { // or jpegData(compressionQuality:)
            let fileName = UUID().uuidString + ".png" // Random file name
            let fileURL = imageFolderMonitor.folderMonitor!.presentedItemURL!.appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                print("Saved image to \(fileURL)")
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    private func setUpNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .ImageFetchCompleted,
            object: nil,
            queue: .main
        ) { notification in
            self.handleImageFetchCompletion(notification)
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
    
    func handleOnTap() {
        
        // Execute the Rust calls in the background
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...50_000_000 {
                if i % 373_033 == 0 || i == 50_000_000 {
                    DispatchQueue.main.async {
                        self.tapCount = i  // Increment the tap count
                    }
                }
                
                var result = get_greetings()
                let swift_result1 = String(cString: result!)
                if i % 373_033 == 0 || i == 50_000_000 {
                    DispatchQueue.main.async {
                        self.text1 = swift_result1
                    }
                }
                free_string(UnsafeMutablePointer(mutating: result))
                
                result = say_hello("Sergio")
                let swift_result2 = String(cString: result!)
                if i % 373_033 == 0 || i == 50_000_000 {
                    DispatchQueue.main.async {
                        self.text2 = swift_result2
                    }
                }
                free_string(UnsafeMutablePointer(mutating: result))
            }
        }
    }
    
    func fetchImageFromRust() {
        isLoading = true
        print("Swift: Fetching image from Rust...")
        fetch_random_image_async(postImageFetchNotification)
    }
    
    private func handleImageFetchCompletion(_ notification: Notification) {
        print("Swift: Handling image fetch completion")
        if let data = notification.userInfo?["data"] as? Data {
            print("Swift: Data received with length: \(data.count)")
            if let image = UIImage(data: data) {
                print("Swift: Image created successfully")
                self.rustImage = image
                self.isLoading = false
                self.tapCount += 1
            } else {
                print("Swift: Unable to create image from data")
                self.rustImage = UIImage(named: "rust-error")
                self.isLoading = false
                self.errorCount += 1
            }
        } else {
            print("Swift: No data received in notification")
            self.rustImage = UIImage(named: "rust-error")
            self.isLoading = false
        }
        DispatchQueue.background(
            background: {
                fetchImageFromRust()
            },
            completion: {
                // when background job finishes, wait 3 seconds and do something in main thread
            })
    }
}

extension Notification.Name {
    static let ImageFetchCompleted = Notification.Name("ImageFetchCompleted")
}

extension DispatchQueue {
    
    static func background(
        delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + delay,
                    execute: {
                        completion()
                    })
            }
        }
    }
    
}

//class ImageFetcher {
//    var onImageFetched: ((Data?) -> Void)?
//
//    init() {
//        NotificationCenter.default.addObserver(
//            self, selector: #selector(imageFetchCompleted), name: .ImageFetchCompleted, object: nil)
//    }
//
//@objc func imageFetchCompleted(_ notification: Notification) {
//    DispatchQueue.main.async {
//        if let data = notification.userInfo?["data"] as? Data {
//            self.onImageFetched?(data)
//        } else {
//            self.onImageFetched?(nil)
//        }
//    }
//}
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
