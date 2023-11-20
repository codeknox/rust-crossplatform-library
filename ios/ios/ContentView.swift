//
//  ContentView.swift
//  ios
//
//  Created by Sergio Ibagy on 11/17/2023.
//

import RustLib
import SwiftUI

struct ContentView: View {
    @State private var text1 = "Tap to start calling\n(it will call into rust 2x * 50,000,000)"
    @State private var text2 = ""
    @State private var tapCount = 0  // Add a state property for the tap count
    @State private var rustImage: UIImage? = nil
    @State private var isLoading = false   // State to track loading status

    var body: some View {
        VStack {
            Text(text1).padding()
                .onTapGesture {
                    handleOnTap()
                }
            Text(text2).padding()
            Text("Call Count: \(tapCount)").padding()
            
            if let image = rustImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200).padding()
            }
            Button("Fetch Image from Rust") {
                fetchImageFromRust()
            }.padding()
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
        DispatchQueue.global(qos: .userInitiated).async {
            let imageData = fetch_random_image()
            guard let rawPtr = imageData.data, imageData.length > 0 else { return }
            
            let data = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: rawPtr),
                            count: Int(imageData.length),
                            deallocator: .free)
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.rustImage = image
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
