//
//  PDFtoTextApp.swift
//  PDFtoText
//
//  Created by Federico on 28/03/25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct PDFtoTextApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.commands {
            CommandGroup(replacing: .newItem) {
                Button("Open PDF") {
                    NotificationCenter.default.post(name: NSNotification.Name("openPDF"), object: nil)
                    
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
    }
}
