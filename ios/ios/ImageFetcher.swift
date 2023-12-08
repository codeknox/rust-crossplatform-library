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
    private let fetchQueue = DispatchQueue(label: "imageFetchQueue", attributes: .concurrent)
    private var timer: Timer?
    private var imageCount = 0
    
    func startFetching(_ folder: URL) {
        guard !isRunning else { return }
        isRunning = true
        folderPath = folder;
        resetBenchmarking()
        
        fetchQueue.async {
            while self.isRunning {
                self.fetchAndSaveImage()
                // Optionally add a short sleep to prevent overwhelming the server
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
    }
    
    func stopFetching() {
        isRunning = false
    }
    
    private func fetchAndSaveImage() {
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching image: \(String(describing: error))")
                return
            }
            
            let filename = UUID().uuidString + ".jpg"
            let filePath = self.folderPath!.appendingPathComponent(filename)
            
            do {
                try data.write(to: filePath)
                self.imageCount += 1
            } catch {
                print("Error saving image: \(error)")
            }
        }.resume()
    }
    
    private func resetBenchmarking() {
        imageCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
            print("Benchmark result: \(self.imageCount) images downloaded in 1 minute.")
            self.stopFetching()
        }
    }
}
