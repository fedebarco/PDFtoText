//
//  ContentView.swift
//  PDFtoText
//
//  Created by Federico on 28/03/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct ContentView: View {
    @State var pdfURLs: [URL] = []
    @State private var selectedTool: Tool? = nil
    @State private var isNavigatingToPDF = false
    @State private var selectedPDFURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("Archivos:")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 20) {
                            LoadPDFView{selectedURL in
                                pdfURLs.append(selectedURL)
                            }
                            ForEach(pdfURLs, id: \.self) { url in
                                Button{
                                    selectedPDFURL = url
                                    selectedTool = Tool.tool1
                                }label: {
                                    if let ns = generateThumbnail(from: url){
                                        Image(nsImage:ns)
                                            .resizable()
                                            .frame(width: 120, height: 160)
                                            .cornerRadius(10)
                                            .shadow(radius: 4)
                                    }else{
                                        Text("\(url)")
                                    }
                                }
                            }
                        }
                    }
                    Text("Herramientas:")
                        .font(.title)
                        .foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 20) {
                            
                            ForEach(Tool.allCases) { tool in
                                Button {
                                    selectedTool = tool
                                } label: {
                                    Image(tool.imageName)
                                        .resizable()
                                        .frame(width:120, height: 120)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedTool) { tool in
                switch tool {
                    case .tool1:
                        PDFMainView(pdfUrl: selectedPDFURL)
                    case .tool2:
                        PDFSplitView(pdfUrl: selectedPDFURL)
                    case .tool3:
                        PDFMainView(pdfUrl: selectedPDFURL)
                    }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenPDFAction"),
                object: nil,
                queue: .main
            ) { _ in
                //pdfViewModel.openPDFPicker()
            }
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("GoStart"),
                object: nil,
                queue: .main
            ) { _ in
                //pdfViewModel.resetDocument()
            }
        }
    }
    
    func generateThumbnail(from url: URL) -> NSImage? {
        
        guard let pdfDoc = PDFKit.PDFDocument(url: url),
              let pdfPage = pdfDoc.page(at: 0) else {
            return nil
        }
        // Calcular una resolución óptima para OCR
        // Una resolución de 144-200 DPI suele ser suficiente para OCR
        let scale: CGFloat = 1.5 // Equilibrio entre calidad y rendimiento
        
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
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
       
    }

}

enum Tool: String, Hashable, CaseIterable, Identifiable {
    case tool1
    case tool2
    case tool3

    var id: String { self.rawValue }

    var imageName: String {
        switch self {
        case .tool1: return "pdftext"
        case .tool2: return "cpdf"
        case .tool3: return "pdfimg"
        }
    }
}



#Preview {
    ContentView()
}
