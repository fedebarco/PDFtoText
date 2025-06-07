//
//  PDFKitView.swift
//  PDFtoText
//
//  Created by Federico on 30/03/25.
//

import SwiftUI
import PDFKit

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = document
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}



#Preview {
    //Users/federico/Libarry?containers?co.federico.PDF/Data/tpm

    let pdfURL = PDFDocument(url:  FileManager.default.temporaryDirectory.appendingPathComponent("dic.pdf"))
    PDFKitView(document: pdfURL!)
}
