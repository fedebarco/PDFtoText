//
//  LoadPDFView.swift
//  PDFtoText
//
//  Created by Federico on 6/06/25.
//

import SwiftUI

struct LoadPDFView: View {
    let onPDFSelected: (URL) -> Void
    
    var body: some View {
        VStack{
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("No hay archivo PDF cargado")
                .font(.title3)
                .foregroundColor(.gray)
            
            Button("Abrir PDF") {
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
                        onPDFSelected(url)
                    }
                }
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

#Preview {
    LoadPDFView { selectedURL in
        print("PDF seleccionado: \(selectedURL)")
    }
}
