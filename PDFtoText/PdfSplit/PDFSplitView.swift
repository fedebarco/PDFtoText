//
//  PDFSplitView.swift
//  PDFtoText
//
//  Created by Federico on 6/06/25.
//

import SwiftUI

struct PDFSplitView: View {
    @State var pdfUrl: URL?
    @State private var ranges: [PageRange] = [PageRange(from: 1, to: 91)]

        var body: some View {
            VStack {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(ranges.indices, id: \.self) { index in
                            VStack {
                                Text("Rango \(index + 1)")
                                    .font(.headline)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 140)
                                    .overlay(
                                        Text("Página \(ranges[index].from)")
                                            .font(.caption)
                                    )

                                Text("a")
                                    .font(.caption)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 140)
                                    .overlay(
                                        Text("Página \(ranges[index].to)")
                                            .font(.caption)
                                    )
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke())
                        }
                    }
                    .padding()
                }

                Divider()

                VStack(spacing: 10) {
                    ForEach(ranges.indices, id: \.self) { index in
                        HStack {
                            Text("Rango \(index + 1):")
                            Stepper("De \(ranges[index].from)", value: $ranges[index].from, in: 1...ranges[index].to)
                            Stepper("a \(ranges[index].to)", value: $ranges[index].to, in: ranges[index].from...999)
                        }
                    }

                    Button("Añadir Rango") {
                        ranges.append(PageRange(from: 91, to: 91))
                    }

                    Button("Dividir PDF") {
                        // Acción de dividir PDF
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .frame(minWidth: 600, minHeight: 500)
        }
}

struct PageRange: Identifiable {
    let id = UUID()
    var from: Int
    var to: Int
}

#Preview {
    PDFSplitView()
}
