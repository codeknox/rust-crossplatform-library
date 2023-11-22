//
//  ContentView.swift
//  ios
//
//  Created by Sergio Ibagy on 11/17/2023.
//

import RustLib
import SwiftUI

// Global function for posting notification
func postImageFetchNotification(dataPtr: UnsafePointer<UInt8>?, length: UInt) {
    print("Swift: Posting Image Fetch Notification \(length)")
    guard let dataPtr = dataPtr else {
        print("Swift: postImageFetchNotification: invalid data, posting")
//        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .ImageFetchCompleted, object: nil, userInfo: ["data": Data()])
            print("Swift: postImageFetchNotification: invalid data, posted, returning")
//        }
        return
    }
    
    print("Swift: postImageFetchNotification: data is valid")
    let data = Data(bytes: dataPtr, count: Int(length))
    NotificationCenter.default.post(
        name: .ImageFetchCompleted, object: nil, userInfo: ["data": data])
}

struct ContentView: View {
    @State private var text1 = "Tap to start calling\n(it will call into rust 2x * 50,000,000)"
    @State private var text2 = ""
    @State private var tapCount = 0  // Add a state property for the tap count
    @State private var rustImage = UIImage(named: "rust-mascot")
    @State private var isLoading = false  // State to track loading status
    
    var body: some View {
        VStack {
            Text("Loading: \(isLoading ? "True" : "False")")
            
            Text(text1).padding()
                .onTapGesture {
                    handleOnTap()
                }
            Text(text2).padding()
            Text("Call Count: \(tapCount)").padding()
            Button("Fetch Image from Rust") {
                fetchImageFromRust()
            }.padding()
            
            ZStack {
                Image(uiImage: rustImage!)
                    .resizable()
                    .scaledToFit()
                if isLoading {
                    TranslucentSpinner()
                }
            }
        }
        .onReceive([self.isLoading].publisher.first(), perform: { value in
            print("isLoading changed to \(value)")
        })
         .onAppear {
            setUpNotificationObserver()
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
            } else
            {
                print("Swift: Unable to create image from data")
                self.rustImage = UIImage(named: "rust-error")
                self.isLoading = false
            }
        } else {
            print("Swift: No data received in notification")
            self.rustImage = UIImage(named: "rust-error")
            self.isLoading = false
        }
    }
}

extension Notification.Name {
    static let ImageFetchCompleted = Notification.Name("ImageFetchCompleted")
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
