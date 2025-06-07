//
//  PDFMainView.swift
//  PDFtoText
//
//  Created by Federico on 1/04/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit

struct PDFMainView: View {
    @State var pdfUrl: URL?
    @StateObject var pdfViewModel: PDFViewModel = PDFViewModel()
    @State var loadedPDFName: String = ""
    @State private var content: String = "Presiona el boton transformar y se obtiene el texto aquí..."
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var isProcessing = false
    @State private var progress: Float = 0.0
    
    // Caché para almacenar resultados de páginas procesadas
    @State private var textCache: [String: [Int: String]] = [:]
    
    // Control de procesamiento concurrente
    private let maxConcurrentTasks = 4
    
    var body: some View {
        
        VStack{
            HStack {
                if let pdfDocument = pdfViewModel.pdfDocument, pdfDocument.pageCount > 0 {
                    VStack {
                        PDFKitView(document: pdfDocument)
                            .onAppear {
                                //pdfViewModel.updatePageCount()
                            }
                        
                        HStack {
                            Text("PDF cargado: \(loadedPDFName)")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if pdfDocument.pageCount > 0 {
                                Text("\(pdfDocument.pageCount) páginas")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                } else {
                    LoadPDFView{selectedURL in
                        loadedPDFName = selectedURL.lastPathComponent
                        pdfViewModel.loadPDF(from: selectedURL)}
                }
                VStack {
                    Button("Transformar") {
                        Task {
                            await MainActor.run {
                                isProcessing = true
                                alertMessage = "Procesando PDF..."
                                content = ""
                                progress = 0.0
                            }
                            
                            if let document = pdfViewModel.pdfDocument {
                                let resultText = await pdfViewModel.handleTransformProcess(
                                    document: document,
                                    onProgressUpdate: { newProgress, partialText in
                                        Task { @MainActor in
                                            self.progress = newProgress
                                            if let partialText = partialText {
                                                self.content = partialText
                                            }
                                        }
                                    }
                                )
                                
                                await MainActor.run {
                                    content = resultText
                                    alertMessage = "Transformación completada."
                                    isProcessing = false
                                    progress = 1.0
                                    
                                }
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isProcessing || pdfViewModel.pdfDocument == nil)
                    
                    if isProcessing {
                        VStack {
                            ProgressView("Procesando PDF...")
                                .padding(.bottom, 5)
                            ProgressView(value: progress)
                                .padding([.leading, .trailing])
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                        }
                        .padding()
                    }
                }
                VStack{
                    TextEditor(text: $content)
                        .frame(height: 200)
                        .border(Color.gray, width: 1)
                    HStack{
                        Text(alertMessage).foregroundColor(alertMessage.contains("Error") ? .red : .green)
                            .padding()
                        
                        if isSaving {
                            ProgressView()
                                .padding()
                        }
                        Button("Descargar TXT") {
                            Task{
                                await pdfViewModel.saveFileWithPanel(content: content, alertMessage: $alertMessage, isSaving: $isSaving, loadedPDFName: loadedPDFName)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }.padding()
            }
            Text("O usa ⌘+S para volver al inicio")
                .foregroundColor(.secondary)
        }.onAppear{
            if let pdfURL = pdfUrl  {
                pdfViewModel.loadPDF(from: pdfURL)
                loadedPDFName = pdfURL.lastPathComponent
            }
        }
    }
    
}


#Preview {
    //Users/federico/Libarry?containers?co.federico.PDF/Data/tpm
    let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("dic.pdf")
    
    PDFMainView(pdfUrl:pdfURL)
}
