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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup{
            ContentView()
        }
        .commands {
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}


