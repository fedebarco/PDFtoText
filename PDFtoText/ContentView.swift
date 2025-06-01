//
//  ContentView.swift
//  PDFtoText
//
//  Created by Federico on 28/03/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject var pdfViewModel = PDFViewModel()
    //@State private var pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("dic.pdf")
    
    var body: some View {
        ZStack {
            if let pdfDocument = pdfViewModel.pdfDocument, pdfDocument.pageCount > 0 {
                PDFMainView(pdfViewModel: pdfViewModel,pdfDocument: pdfDocument)
                    
            } else {
                VStack {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No hay archivo PDF cargado")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Button("Abrir PDF") {
                        pdfViewModel.openPDFPicker()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding()
                    
                    Text("O usa ⌘+O para abrir un archivo")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenPDFAction"),
                object: nil,
                queue: .main
            ) { _ in
                pdfViewModel.openPDFPicker()
            }
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("GoStart"),
                object: nil,
                queue: .main
            ) { _ in
                pdfViewModel.resetDocument()
            }
        }
    }
}

#Preview {
    ContentView()
}
