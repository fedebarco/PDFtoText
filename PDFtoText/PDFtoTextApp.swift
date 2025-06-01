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
    @State private var isMainWindowVisible = true

    var body: some Scene {
        WindowGroup {
            if isMainWindowVisible {
                ContentView()
            }
        }.commands {
            CommandMenu("View") {
                Button("Go to start"){
                    NotificationCenter.default.post(name: NSNotification.Name("GoStart"), object: nil)
                }.keyboardShortcut("S", modifiers: [.command])
            }
            CommandGroup(replacing: .newItem) {
                Button("Open PDF") {
                    NotificationCenter.default.post(name: NSNotification.Name("openPDF"), object: nil)
                    
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
    }
}
