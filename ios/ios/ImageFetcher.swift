//
//  ImageFetcher.swift
//  ios
//
//  Created by Ibagy, Sergio on 12/7/23.
//

import Foundation
import UIKit

class ImageFetcher {
    private var isRunning = false
    private let imageURL = URL(string: "https://picsum.photos/200/300")!
    private var folderPath: URL?
    private var imageCount = 0
    private var timer: Timer?
    
    func startFetching(_ folder: URL) {
        guard !isRunning else { return }
        isRunning = true
        folderPath = folder
        resetBenchmarking()
        
        Task {
            while self.isRunning {
                await fetchAndSaveImage()
            }
        }
    }
    
    func stopFetching() {
        isRunning = false
    }
    
    private func fetchAndSaveImage() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            let filename = UUID().uuidString + ".jpg"
            let filePath = folderPath!.appendingPathComponent(filename)
            try data.write(to: filePath)
            imageCount += 1
        } catch {
            print("Error during fetch/save: \(error)")
        }
    }
    
    private func resetBenchmarking() {
        imageCount = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
            print("Benchmark result: \(self.imageCount) images downloaded in 1 minute.")
            self.stopFetching()
        }
    }
}
