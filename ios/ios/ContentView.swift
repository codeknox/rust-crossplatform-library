//
//  ContentView.swift
//  ios
//
//  Created by Sergio Ibagy on 11/17/2023.
//

import SwiftUI
import RustLib

struct ContentView: View {
    @State private var text1 = "Tap to start calling\n(it will call into rust 2x * 50,000,000)"
    @State private var text2 = ""
    @State private var tapCount = 0  // Add a state property for the tap count
    
    var body: some View {
        VStack {
            Text(text1).padding()
            Text(text2).padding()
            Text("Call Count: \(tapCount)") // Display the tap count
        }
        .onTapGesture {
            handleOnTap()
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
