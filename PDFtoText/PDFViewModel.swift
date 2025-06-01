//
//  PDFViewModel.swift
//  PDFtoText
//
//  Created by Federico on 30/03/25.
//

import Foundation
import PDFKit
import SwiftUI
import Vision
import UniformTypeIdentifiers

class PDFViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var loadedPDFName: String = ""
    @Published var pageCount: Int = 0
    
    private let maxConcurrentTasks = 4
    private var textCache: [String: [Int: String]] = [:]
        
    func updatePageCount() {pageCount = pdfDocument?.pageCount ?? 0}
    
    func openPDFPicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.pdf]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Seleccionar archivo PDF"
        openPanel.message = "Por favor, selecciona un archivo PDF para abrir"
        openPanel.prompt = "Abrir PDF"
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                loadPDF(from: url)
                loadedPDFName = url.lastPathComponent
            }
        }
    }
    
    func loadPDF(from url: URL) {
        if let document = PDFDocument(url: url) {
            DispatchQueue.main.async {
                self.pdfDocument = document
                self.updatePageCount()
            }
        }
    }
    
    // En tu PDFViewModel
    func resetDocument() {
        // Limpiar cualquier estado relacionado antes de establecer nil
        // Por ejemplo, si tienes páginas cargadas, texto extraído, etc.
        pageCount = 0
        // Finalmente establecer el documento como nil
        pdfDocument = nil
    }
    
    
    func handleTransformProcess(
            document: PDFDocument,
            onProgressUpdate: @escaping (Float, String?) -> Void
        ) async -> String {
            var content = ""
            var progress: Float = 0.0
            var lastPartialResult: String? = nil

            let result = await transformPDFToText(
                document: document,
                onProgressUpdate: { newProgress, partialText in
                    progress = newProgress
                    if let partialText = partialText, newProgress > 0.2 {
                        content = partialText
                        lastPartialResult = partialText
                    }
                    onProgressUpdate(newProgress, partialText)
                }
            )

            return result.text.isEmpty ? "No se pudo extraer texto." : result.text
        }
    
    @MainActor
    func saveFileWithPanel(content: String, alertMessage: Binding<String>, isSaving: Binding<Bool>) async {
        isSaving.wrappedValue = true
        defer { isSaving.wrappedValue = false }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.plainText]
        savePanel.canCreateDirectories = true
        savePanel.title = "Guardar como"
        
        // Sugerir nombre basado en el PDF
        let defaultName = (loadedPDFName as NSString).deletingPathExtension + "_transformado.txt"
        savePanel.nameFieldStringValue = defaultName

        // Usar última carpeta si está disponible
        if let lastDir = UserDefaults.standard.url(forKey: "LastSaveDirectory") {
            savePanel.directoryURL = lastDir
        }

        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                alertMessage.wrappedValue = "Archivo guardado exitosamente en: \(url.path)"
                
                // Guardar la carpeta para futuras descargas
                let folderURL = url.deletingLastPathComponent()
                UserDefaults.standard.set(folderURL, forKey: "LastSaveDirectory")
            } catch {
                alertMessage.wrappedValue = "Error al guardar archivo: \(error.localizedDescription)"
            }
        } else {
            alertMessage.wrappedValue = "Operación cancelada."
        }
    }

    
    
    func saveFileToDownloads(content: String, alertMessage: Binding<String>? = nil, isSaving: Binding<Bool>? = nil) async {
        let fileManager = FileManager.default
        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let pdfName = loadedPDFName
                    
            // Extraer el nombre base sin extensión y añadir la extensión .txt
            let fileName: String
            if let dotIndex = pdfName.lastIndex(of: ".") {
                let nameWithoutExtension = String(pdfName[..<dotIndex])
                fileName = nameWithoutExtension + ".txt"
            } else {
                // Si no tiene extensión, simplemente añadir .txt
                fileName = pdfName + ".txt"
            }
            let fileURL = downloadsURL.appendingPathComponent(fileName)
            
            await MainActor.run {
                        isSaving?.wrappedValue = true
                        alertMessage?.wrappedValue = "Guardando archivo..."
                    }

            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                await MainActor.run {
                    alertMessage?.wrappedValue = "El archivo se ha guardado en: \(fileURL.path)"
                    isSaving?.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    alertMessage?.wrappedValue = "Error al guardar el archivo: \(error.localizedDescription)"
                    isSaving?.wrappedValue = false
                }
            }
        }
    }
    
    private func recognizeText(from image: NSImage?) async -> String? {
        guard let image = image,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLanguages = ["es", "en"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try await Task.detached {
                try handler.perform([request])
            }.value
            return request.results?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
        } catch {
            print("Error en reconocimiento de texto: \(error)")
            return nil
        }
    }
    
    func processPage(pdfDocument: PDFDocument, pageIndex: Int) async -> (Int, String?) {
        guard let pdfPage = pdfDocument.page(at: pageIndex) else { return (pageIndex, nil) }
        
        // Obtener la imagen con configuración optimizada
        if let image = await pdfPageToNSImage(pdfPage: pdfPage) {
            return (pageIndex, await recognizeText(from: image))
        }
        return (pageIndex, nil)
    }

    func pdfPageToNSImage(pdfPage: PDFPage) async -> NSImage? {
        // Calcular una resolución óptima para OCR
        // Una resolución de 144-200 DPI suele ser suficiente para OCR
        let scale: CGFloat = 1.5 // Equilibrio entre calidad y rendimiento
        
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
        return await Task.detached {
            let image = NSImage(size: scaledSize)
            
            image.lockFocus()
            if let context = NSGraphicsContext.current?.cgContext {
                // Establecer el fondo blanco
                context.setFillColor(CGColor.white)
                context.fill(CGRect(origin: .zero, size: scaledSize))
                
                // Aplicar escala para mantener la calidad adecuada
                context.scaleBy(x: scale, y: scale)
                
                // Configurar para mejor calidad OCR
                context.setAllowsAntialiasing(true)
                context.setShouldSmoothFonts(true)
                
                // Dibujar la página
                pdfPage.draw(with: .mediaBox, to: context)
            }
            image.unlockFocus()
            
            return image
        }.value
    }
    
    
    // Función reutilizable y parametrizada para transformar PDF a texto
    func transformPDFToText(
        document: PDFDocument,
        onProgressUpdate: @escaping (Float, String?) -> Void
    ) async -> (text: String, partialResult: String?) {
        // Obtener número de páginas
        let pageCount = document.pageCount
        guard pageCount > 0 else {
            return ("", nil)
        }
        
        // Generar identificador único para el PDF para el caché
        let pdfIdentifier = document.documentURL?.absoluteString ?? UUID().uuidString
        
        // Verificar si tenemos un caché para este documento
        var documentCache = textCache[pdfIdentifier] ?? [:]
        var processedResults = [(Int, String?)](repeating: (0, nil), count: pageCount)
        var partialResult: String? = nil
        
        // Procesar las páginas en lotes para controlar la concurrencia
        for batchStart in stride(from: 0, to: pageCount, by: maxConcurrentTasks) {
            let batchEnd = min(batchStart + maxConcurrentTasks, pageCount)
            let batchRange = batchStart..<batchEnd
            
            let batchResults = await withTaskGroup(of: (Int, String?).self) { group in
                for pageIndex in batchRange {
                    group.addTask {
                        // Verificar si ya tenemos este resultado en caché
                        if let cachedText = documentCache[pageIndex] {
                            return (pageIndex, cachedText)
                        }
                        return await self.processPage(pdfDocument: document, pageIndex: pageIndex)
                    }
                }
                
                var results = [(Int, String?)]()
                for await result in group {
                    results.append(result)
                    let partialResult = processedResults[0..<batchEnd]
                            .compactMap { $0.1 }
                            .joined(separator: "\n\n--- Página ---\n\n")
                        
                    
                    // Calcular y actualizar el progreso
                    let currentProgress = Float(results.count + batchStart) / Float(pageCount)
                    onProgressUpdate(currentProgress, partialResult)
                }
                return results
            }
            
            // Guardar los resultados del lote en su posición correspondiente
            for result in batchResults {
                processedResults[result.0] = result
                
                // Guardar en caché para futuras transformaciones
                if let text = result.1 {
                    documentCache[result.0] = text
                }
            }
            
            // Actualización parcial del texto para mostrar progreso
            if batchEnd % 5 == 0 || batchEnd == pageCount {
                partialResult = processedResults[0..<batchEnd]
                    .compactMap { $0.1 }
                    .joined(separator: "\n\n--- Página ---\n\n")
            }
        }
        
        // Guardar en caché para futuras transformaciones
        textCache[pdfIdentifier] = documentCache
        
        // Compilar todos los resultados
        let fullText = processedResults
            .compactMap { $0.1 }
            .joined(separator: "\n\n--- Página ---\n\n")
        
        return (fullText, partialResult)
    }
    
}
